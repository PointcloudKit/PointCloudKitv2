import Metal
import MetalKit
import ARKit

public class PointCloudRenderer {

    // MARK: - Settings and Constants

    // Maximum number of points we store in the point cloud
    let maxPoints = 500_000
    // Number of sample points on the grid <=> How many point are sampled per frame
    let numGridPoints = 750 // Apple's Default 500
    // Particle's size in pixels
    let particleSize: Float = 5 // Apple's Default 10
    let orientation = UIInterfaceOrientation.portrait
    // Camera's threshold values for detecting when the camera moves so that we can accumulate the points
    let cameraRotationThreshold = cos(2 * .degreesToRadian)
    let cameraTranslationThreshold: Float = pow(0.02, 2)   // (meter-squared)
    // The max number of command buffers in flight
    let maxInFlightBuffers = 3
    lazy var rotateToARCamera = Self.makeRotateToARCameraMatrix(orientation: orientation)

    // MARK: - Engine

    let session: ARSession

    // Metal objects and textures
    let device: MTLDevice
    let library: MTLLibrary
    let renderDestination: RenderDestinationProvider
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
                                                            index: kGridPoints.rawValue, options: [])

    // MARK: - Buffers

    // MARK: RGB buffer
    lazy var rgbUniforms: RGBUniforms = {
        var uniforms = RGBUniforms()
        uniforms.radius = rgbRadius
        uniforms.viewToCamera.copy(from: viewToCamera)
        uniforms.viewRatio = Float(viewportSize.width / viewportSize.height)
        return uniforms
    }()
    var rgbUniformsBuffers = [MetalBuffer<RGBUniforms>]()

    // MARK: Point Cloud buffer
    lazy var pointCloudUniforms: PointCloudUniforms = {
        var uniforms = PointCloudUniforms()
        uniforms.maxPoints = Int32(maxPoints)
        uniforms.confidenceThreshold = Int32(confidenceThreshold)
        uniforms.particleSize = particleSize
        uniforms.cameraResolution = cameraResolution
        return uniforms
    }()
    var pointCloudUniformsBuffers = [MetalBuffer<PointCloudUniforms>]()

    // MARK: Particles buffer
    var particlesBuffer: MetalBuffer<ParticleUniforms>
    var currentPointIndex = 0
    var currentPointCount = 0

    // MARK: - Sampling

    // Camera data
    var sampleFrame: ARFrame { session.currentFrame! }
    lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
    lazy var viewToCamera = sampleFrame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
    lazy var lastCameraTransform = sampleFrame.camera.transform

    // MARK: - Public Interfaces

    public var confidenceThreshold = 1 {
        didSet {
            // apply the change for the shader
            pointCloudUniforms.confidenceThreshold = Int32(confidenceThreshold)
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
    public init(session: ARSession, metalDevice device: MTLDevice, renderDestination: RenderDestinationProvider) {
        self.session = session
        self.device = device
        self.renderDestination = renderDestination

        library = device.makeDefaultLibrary()!
        commandQueue = device.makeCommandQueue()!

        // initialize our buffers
        for _ in 0 ..< maxInFlightBuffers {
            rgbUniformsBuffers.append(.init(device: device, count: 1, index: 0))
            pointCloudUniformsBuffers.append(.init(device: device, count: 1, index: kPointCloudUniforms.rawValue))
        }
        particlesBuffer = .init(device: device, count: maxPoints, index: kParticleUniforms.rawValue)

        // rbg does not need to read/write depth
        let relaxedStateDescriptor = MTLDepthStencilDescriptor()
        relaxedStencilState = device.makeDepthStencilState(descriptor: relaxedStateDescriptor)!

        // setup depth test for point cloud
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .lessEqual
        depthStateDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!

        inFlightSemaphore = DispatchSemaphore(value: maxInFlightBuffers)
    }
}
