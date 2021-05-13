import Foundation
import Metal
import MetalKit
import ARKit
import Combine
import Common

public enum ConfidenceThreshold: Int32, CaseIterable {
    case /*low = 0,*/ medium = 1, high
}

public enum SamplingRate: Float, CaseIterable {
    case slow = 0.5, regular = 1, fast = 1.5
}

public final class RenderingService: ObservableObject {

    // MARK: - Settings and Constants

    // Maximum number of points we store in the point cloud
    let maxPoints = 524288 // 4096 * 128 // Apples's default was 500k
    // Number of sample points on the grid <=> How many point are sampled per frame
    let numGridPoints = 512 // Apple's Default 500
    // Particle's size in pixels
    let particleSize: Float = 7 // Apple's Default 10
    let orientation = UIInterfaceOrientation.portrait
    // Camera's threshold values for detecting when the camera moves so that we can accumulate the points
    lazy var cameraRotationThreshold = Self.updateCameraRotationThreshold()
    lazy var cameraTranslationThreshold = Self.updateCameraTranslationThreshold()
    // The max number of command buffers in flight
    let maxInFlightBuffers = 3
    lazy var rotateToARCamera = Self.makeRotateToARCameraMatrix(orientation: orientation)

    private class func updateCameraRotationThreshold(with rate: SamplingRate = .regular) -> Float {
        let degree = (2 / rate.rawValue)
        return cos(degree * .degreesToRadian)
    }

    private class func updateCameraTranslationThreshold(with rate: SamplingRate = .regular) -> Float {
        let meter = (0.02 / rate.rawValue)
        return pow(meter, 2) // (meter-squared)
    }

    // MARK: - Engine

    public let session = ARSession()

    // Metal objects and textures
    public let device: MTLDevice
    let library: MTLLibrary
    public var renderDestination: RenderDestinationProvider?
    let relaxedStencilState: MTLDepthStencilState
    let depthStencilState: MTLDepthStencilState
    let commandQueue: MTLCommandQueue
    lazy var unprojectPipelineState = makeUnprojectionPipelineState()!
    lazy var rgbPipelineState = makeRGBPipelineState()!
    lazy var particlePipelineState = makeParticlePipelineState()!
    // texture cache for captured image
    lazy var textureCache = makeTextureCache()
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    var depthTexture: CVMetalTexture?
    var confidenceTexture: CVMetalTexture?

    // Multi-buffer rendering pipeline
    let inFlightSemaphore: DispatchSemaphore
    var currentBufferIndex = 0

    // The current viewport size
    var viewportSize = CGSize()
    // The grid of sample points
    lazy var gridPointsBuffer = MetalBuffer<Float2>(device: device, array: makeGridPoints(),
                                                            index: Index.Buffer.gridPoints.rawValue, options: [])

    // MARK: - Buffers

    // MARK: RGB buffer
    lazy var rgbUniforms: RGBUniforms = {
        var uniforms = RGBUniforms()
        uniforms.radius = rgbRadius
        uniforms.viewToCamera.copy(from: viewToCamera)
        uniforms.viewRatio = Float(viewportSize.height / viewportSize.width)
        return uniforms
    }()
    var rgbUniformsBuffers = [MetalBuffer<RGBUniforms>]()

    // MARK: Point Cloud buffer
    lazy var pointCloudUniforms: PointCloudUniforms = {
        var uniforms = PointCloudUniforms()
        uniforms.maxPoints = Int32(maxPoints)
        uniforms.confidenceThreshold = confidenceThreshold
        uniforms.particleSize = particleSize
        uniforms.cameraResolution = cameraResolution
        return uniforms
    }()
    var pointCloudUniformsBuffers = [MetalBuffer<PointCloudUniforms>]()

    // MARK: Particles buffer
    private(set) public var particlesBuffer: MetalBuffer<ParticleUniforms>
    var currentPointIndex = 0
    @Published public var currentPointCount = 0

    // MARK: - Sampling

    // Camera data
    var sampleFrame: ARFrame { session.currentFrame! }
    lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
    lazy var viewToCamera = sampleFrame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
    lazy var lastCameraTransform = sampleFrame.camera.transform

    // MARK: - Public Interfaces

    // Used by the outside world to access the captured particles without too many memory fuckery
    @Published public var particleBufferWrapper: ParticleBufferWrapper

    @Published public var running: Bool = false {
        didSet {
            switch running {
            case true:
                session.run(defaultARSessionConfiguration)
            case false:
                session.pause()
            }
        }
    }

    // A.k.a. accumulate
    @Published public var capturing: Bool = false

    @Published public var flush: Bool = false {
        didSet {
            if flush == true {
                particlesBuffer.assign(Array(repeating: ParticleUniforms(), count: particlesBuffer.count))
                currentPointCount = 0
                currentPointIndex = 0
                flush = false
            }
        }
    }

    public var confidenceThreshold: ConfidenceThreshold = .medium {
        didSet {
            // apply the change for the shader
            pointCloudUniforms.confidenceThreshold = confidenceThreshold
        }
    }

    public var horizontalSamplingRate: SamplingRate = .regular {
        didSet {
            cameraRotationThreshold = Self.updateCameraRotationThreshold(with: horizontalSamplingRate)
        }
    }

    public var verticalSamplingRate: SamplingRate = .regular {
        didSet {
            cameraTranslationThreshold = Self.updateCameraTranslationThreshold(with: verticalSamplingRate)
        }
    }

    public var rgbRadius: Float = 0 {
        didSet {
            // apply the change for the shader
            rgbUniforms.radius = rgbRadius
        }
    }

    // MARK: - Public

    /// Using an `MTLDevice`, process the RGBD live data sampled by the `ARSession` object and renders a point cloud at `renderDestination`.
    /// - Parameters:
    ///   - session: The input providing RGBD samples from the user capture.
    ///   - device: The Metal device used for processing information and generating a render (The phone GPU)
    ///   - renderDestination: Where the render is being draw for the user to see
    public init(metalDevice device: MTLDevice, renderDestination: RenderDestinationProvider? = nil) {
        self.device = device
        self.renderDestination = renderDestination

        // Create the library of metal functions
        // swiftlint:disable:next force_try
        library = try! device.makeDefaultLibrary(bundle: Bundle.module)
        commandQueue = device.makeCommandQueue()!

        // initialize our buffers
        for _ in 0 ..< maxInFlightBuffers {
            rgbUniformsBuffers.append(.init(device: device, count: 1, index: 0))
            pointCloudUniformsBuffers.append(.init(device: device, count: 1,
                                                   index: Index.Buffer.pointCloudUniforms.rawValue))
        }
        particlesBuffer = .init(device: device, count: maxPoints,
                                index: Index.Buffer.particleUniforms.rawValue,
                                options: [MTLResourceOptions.storageModeShared]) // not sure it need to be explicit

        // rbg does not need to read/write depth
        let relaxedStateDescriptor = MTLDepthStencilDescriptor()
        relaxedStencilState = device.makeDepthStencilState(descriptor: relaxedStateDescriptor)!

        // setup depth test for point cloud
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .lessEqual
        depthStateDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!

        inFlightSemaphore = DispatchSemaphore(value: maxInFlightBuffers)
        // Starts
        particleBufferWrapper = ParticleBufferWrapper(buffer: particlesBuffer)
        running = true
    }

    // MARK: - AK Kit Session

    var defaultARSessionConfiguration: ARConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        return configuration
    }()
}
