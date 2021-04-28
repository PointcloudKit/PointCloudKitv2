//
//  CaptureViewerModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SceneKit
import PointCloudRendererService
import ProcessorService
import Common
import Combine

enum NodeIdentifier: String {
    case camera = "com.pointCloudKit.nodes.camera"
    case pointCloudRoot = "com.pointCloudKit.nodes.pointCloudRootRoot"
}

final public class CaptureViewerModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var capture: PointCloudCapture
    @Published private var lastObject: Object3D?
    @Published private var object: Object3D?
    private let processor = ProcessorService()

    @Published var rendering = false
    @Published var processing = false
    @Published var undoAvailable = false
    @Published var exportPlyAvailable = false
    @Published var exportProgress = 1.0
    @Published var exporting = false
    @Published var vertexCount = 0
    @Published var normalCount = 0
    @Published var triangleCount = 0

    // MARK: - Scene Elements

    lazy public var scene: SCNScene = {
        let scene = generateScene(from: capture)
        let cameraNode = self.cameraNode

        cameraNode.look(at: scene.rootNode.position)
        cameraNode.position.z += 5
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ambientLightNode)
        scene.background.contents = UIColor.black
        return scene
    }()

    lazy var cameraNode: SCNNode = {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.name = NodeIdentifier.camera.rawValue
        return cameraNode
    }()

    lazy var ambientLightNode: SCNNode = {
        let ambientLightNode = SCNNode()
        let light = SCNLight()

        light.type = .ambient
        ambientLightNode.light = light
        return ambientLightNode
    }()

    // MARK: - Methods

    public init(capture: PointCloudCapture) {
        self.capture = capture

        // Generate Object
        convert(capture: capture)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] object in
                self?.object = object
            })
            .store(in: &cancellables)

        $object
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] object in
                self?.vertexCount = object?.vertices.count ?? 0
                self?.normalCount = object?.vertexNormals.count ?? 0
                self?.triangleCount = object?.triangles.count ?? 0
            })
            .map { object in object != nil }
            .assign(to: &$exportPlyAvailable)

        $lastObject
            .receive(on: DispatchQueue.main)
            .map { $0 != nil }
            .assign(to: &$undoAvailable)

        $exportProgress
            .receive(on: DispatchQueue.main)
            .map { $0 != 1.0 }
            .assign(to: &$exporting)
    }

    private func convert(capture: PointCloudCapture) -> Future<Object3D, Never> {
        Future { promise in
            let particles = capture.buffer.getMemoryRepresentationCopy(for: capture.count)
            let object = Object3D(vertices: particles.map(\.position),
                                  vertexConfidence: particles.map({ particle in UInt(particle.confidence) }),
                                  vertexColors: particles.map(\.color))
            promise(.success(object))
        }
    }

    func scnFile() -> SCNFile {
        let file = SCNFile(scene: scene)

        file.$writeToDiskProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$exportProgress)
        return file
    }

    func plyFile() -> PLYFile? {
        guard let object = object else { return nil }
        let file = PLYFile(object: object)

        file.$writeToDiskProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$exportProgress)
        return file
    }

    // MARK: - Point Cloud Processing operations - Parameters are from the `ProcessorParameters` in Model
    func voxelDownsampling(parameters: ProcessorParameters.VoxelDownSampling) {
        vertexProcessing(with: [VertexProcessor.voxelDownSampling(voxelSize: parameters.voxelSize)])
    }

    func statisticalOutlierRemoval(parameters: ProcessorParameters.OutlierRemoval.Statistical) {
        vertexProcessing(with: [VertexProcessor.statisticalOutlierRemoval(neighbors: parameters.neighbors,
                                                                          stdRatio: parameters.stdRatio)])
    }

    func radiusOutlierRemoval(parameters: ProcessorParameters.OutlierRemoval.Radius) {
        vertexProcessing(with: [VertexProcessor.radiusOutlierRemoval(pointsCount: parameters.pointsCount,
                                                                     radius: parameters.radius)])
    }

    func normalsEstimation(parameters: ProcessorParameters.NormalsEstimation) {
        vertexProcessing(with: [VertexProcessor.normalsEstimation(radius: parameters.radius,
                                                                  maxNearestNeighbors: parameters.maxNearestNeighbors)])
    }

    func poissonSurfaceReconstruction(parameters: ProcessorParameters.SurfaceReconstruction.Poisson) {
        // FAUT KI YE LE NORMAL
        faceProcessing(with: [FaceProcessor.poissonSurfaceReconstruction(depth: parameters.depth)])
    }

    func undo() {
        processing = true
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self, let lastObject = self.lastObject else { return }
            self.capture.buffer.assign(with: lastObject.particles())
            DispatchQueue.main.async {
                self.object = lastObject
                self.lastObject = nil
                self.processing = false
            }
        }
    }
}

// MARK: - Internals
extension CaptureViewerModel {
    private func generateScene(from capture: PointCloudCapture) -> SCNScene {
        rendering = true
        let scene = SCNScene()
        // Create point cloud nodes and add to the scene
        capture.generatePointCloudNode()
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (pointCloudRootNode, vertexCount) in
                self?.rendering = false
                self?.vertexCount = vertexCount
                scene.rootNode.addChildNode(pointCloudRootNode)
            }
            .store(in: &cancellables)
        return scene
    }

    private func vertexProcessing(with processors: [VertexProcessor]) {
        processing = true
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self, let plyFile = self.plyFile() else { return }
            self.processor.process(plyFile, with: processors)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        return
                    case let .failure(error):
                        print(error.localizedDescription)
                        return
                    }
                }, receiveValue: { object in
                    self.capture.reloadBufferContent(with: object.particles())
                    DispatchQueue.main.async {
                        self.lastObject = self.object
                        self.object = object
                        self.processing = false
                    }
                })
                .store(in: &self.cancellables)
        }
    }

    private func faceProcessing(with processors: [FaceProcessor]) {
        processing = true
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self, let plyFile = self.plyFile() else { return }
            self.processor.process(plyFile, with: processors)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        return
                    case let .failure(error):
                        print(error.localizedDescription)
                        return
                    }
                }, receiveValue: { object in
                    self.capture.reloadBufferContent(with: object.particles())
                    DispatchQueue.main.async {
                        self.lastObject = self.object
                        self.object = object
                        self.processing = false
                    }
                })
                .store(in: &self.cancellables)
        }
    }
}
