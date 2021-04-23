//
//  CaptureViewerViewModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SceneKit
import PointCloudRendererService
import PointCloudProcessorService
import Common
import Combine

final public class CaptureViewerViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let model: CaptureViewerModel
    private let pointCloudProcessor = PointCloudProcessorService()

    @Published var pointCloudRendering = false
    @Published var pointCloudProcessing = false
    @Published var undoAvailable = false
    @Published var vertexCount: Int = 0

    // MARK: - Scene Elements

    lazy public var scene: SCNScene = {
        let scene = generateScene(from: model.capture)
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

    public init(model: CaptureViewerModel) {
        self.model = model
        pointCloudProcessor.$previousPointCloud
            .map { $0 != nil }
            .assign(to: &$undoAvailable)
    }

    func scnFile() -> SCNFile {
        SCNFile(scene: scene)
    }

    func plyFile() -> PLYFile {
        PLYFile(particles: model.capture.buffer.getMemoryRepresentationCopy(for: vertexCount))
    }

    // MARK: - Point Cloud Processing operations - Parameters are from the `ProcessorParameters` in Model
    func voxelDownsampling() {
        pointCloudProcessing(with: [.voxelDownSampling(voxelSize: model.processorParameters.voxelDownSampling.voxelSize)])
    }

    func statisticalOutlierRemoval() {
        let parameters = model.processorParameters.outlierRemoval.statistical
        return pointCloudProcessing(with: [.statisticalOutlierRemoval(neighbors: parameters.neighbors,
                                                                      stdRatio: parameters.stdRatio)])
    }

    func radiusOutlierRemoval() {
        let parameters = model.processorParameters.outlierRemoval.radius
        pointCloudProcessing(with: [.radiusOutlierRemoval(pointsCount: parameters.pointsCount,
                                                          radius: parameters.radius)])
    }

    func undo() {
        guard let previousPointCloud = pointCloudProcessor.getPreviousPointCloudForUndo() else { return }

        pointCloudProcessing = true
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            self.model.capture.buffer.assign(with: previousPointCloud)
            DispatchQueue.main.async {
                self.vertexCount = previousPointCloud.count
                self.pointCloudProcessing = false
            }
        }
    }
}

// MARK: - Internals
extension CaptureViewerViewModel {
    private func generateScene(from capture: PointCloudCapture) -> SCNScene {
        pointCloudRendering = true
        let scene = SCNScene()
        // Create point cloud nodes and add to the scene
        capture.generatePointCloudNode()
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (pointCloudRootNode, vertexCount) in
                self?.pointCloudRendering = false
                self?.vertexCount = vertexCount
                scene.rootNode.addChildNode(pointCloudRootNode)
            }
            .store(in: &cancellables)
        return scene
    }

    private func updateScene(with capture: PointCloudCapture) {
        pointCloudRendering = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            // Remove previous points
            self.scene.rootNode
                .childNode(withName: NodeIdentifier.pointCloudRoot.rawValue, recursively: false)?
                .removeFromParentNode()
            // Create point cloud nodes and add to the scene
            capture.generatePointCloudNode()
                .receive(on: RunLoop.main)
                .sink { (pointCloudRootNode, vertexCount) in
                    self.pointCloudRendering = false
                    self.vertexCount = vertexCount
                    self.scene.rootNode.addChildNode(pointCloudRootNode)
                }
                .store(in: &self.cancellables)
        }
    }

    private func pointCloudProcessing(with processors: [PointCloudProcessor]) {
        pointCloudProcessing = true
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            self.pointCloudProcessor.process(self.plyFile(), with: processors)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        return
                    case let .failure(error):
                        print(error.localizedDescription)
                        return
                    }
                }, receiveValue: { downSampledParticles in
                    self.model.capture.buffer.assign(with: downSampledParticles)
                    DispatchQueue.main.async {
                        self.vertexCount = downSampledParticles.count
                        self.pointCloudProcessing = false
                    }
                })
                .store(in: &self.cancellables)
        }
    }
}
