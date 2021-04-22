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
    private let positionVertex = PointCloudCapture.Component.position
    private let colorVertex = PointCloudCapture.Component.color
    //        let confidence = PointCloudCapture.Component.confidence
    private let model: CaptureViewerModel
    private let pointCloudProcessor = PointCloudProcessorService()

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

    // MARK: - Point Cloud Processing operations
    func voxelDownsampling(voxelSize: Double = 0.02) {
        pointCloudProcessing(with: [.voxelDownSampling(voxelSize: voxelSize)])
    }

    func statisticalOutlierRemoval(neighbors: Int = 20, stdRatio: Double = 2.0) {
        pointCloudProcessing(with: [.statisticalOutlierRemoval(neighbors: neighbors, stdRatio: stdRatio)])
    }

    func radiusOutlierRemoval(pointsCount: Int = 16, radius: Double = 0.05) {
        pointCloudProcessing(with: [.radiusOutlierRemoval(pointsCount: pointsCount, radius: radius)])
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
    private func pointCloudNode(from capture: PointCloudCapture) -> SCNNode {
        let rawBuffer = capture.buffer.rawBuffer
        let dataStride = capture.stride
        let vertexCount = capture.count

        // Our data sources from Metal
        let positionSource = SCNGeometrySource(buffer: rawBuffer,
                                               vertexFormat: positionVertex.format,
                                               semantic: positionVertex.semantic,
                                               vertexCount: vertexCount,
                                               dataOffset: positionVertex.dataOffset,
                                               dataStride: dataStride)

        let colorSource = SCNGeometrySource(buffer: rawBuffer,
                                            vertexFormat: colorVertex.format,
                                            semantic: colorVertex.semantic,
                                            vertexCount: vertexCount,
                                            dataOffset: colorVertex.dataOffset,
                                            dataStride: dataStride)

        // Not used for now. Not sure how to use at this point. In metal can be useful
//        let confidenceSource = SCNGeometrySource(buffer: rawBuffer,
//                                                 vertexFormat: confidence.format,
//                                                 semantic: confidence.semantic,
//                                                 vertexCount: vertexCount,
//                                                 dataOffset: confidence.dataOffset,
//                                                 dataStride: dataStride)

        // Points
        let particles = SCNGeometryElement(data: nil,
                                           primitiveType: .point,
                                           primitiveCount: vertexCount,
                                           bytesPerIndex: MemoryLayout<Int>.size)
        particles.pointSize = 1.0
        particles.minimumPointScreenSpaceRadius = 2.5
        particles.maximumPointScreenSpaceRadius = 2.5

        let pointCloudGeometry = SCNGeometry(sources: [positionSource, colorSource/*, confidenceSource*/],
                                             elements: [particles])
        let pointCloudRootNode = SCNNode(geometry: pointCloudGeometry)
        pointCloudRootNode.name = NodeIdentifier.pointCloudRoot.rawValue

        self.vertexCount = vertexCount

        return pointCloudRootNode
    }

    private func generateScene(from capture: PointCloudCapture) -> SCNScene {
        let scene = SCNScene()

        let pointCloudRootNode = pointCloudNode(from: capture)
        scene.rootNode.addChildNode(pointCloudRootNode)
        return scene
    }

    private func updateScene(with capture: PointCloudCapture) {
        // Remove previous points
        scene.rootNode
            .childNode(withName: NodeIdentifier.pointCloudRoot.rawValue, recursively: false)?
            .removeFromParentNode()

        // Create point cloud nodes and add to the scene
        scene.rootNode.addChildNode(pointCloudNode(from: capture))
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
