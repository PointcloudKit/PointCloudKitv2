//
//  CaptureViewerViewModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SceneKit
import PointCloudRendererService
import PointCloudProcessorService

final public class CaptureViewerViewModel: ObservableObject {
    private let positionVertex = PointCloudCapture.Component.position
    private let colorVertex = PointCloudCapture.Component.color
    //        let confidence = PointCloudCapture.Component.confidence

    private let model: CaptureViewerModel
    private let pointCloudProcessor = PointCloudProcessorService()

    @Published var pointCloudProcessing = false

    // Will this update?Check later when processing can be done
    @Published var vertexCount: Int = 0

    public init(model: CaptureViewerModel) {
        self.model = model
    }

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

    func optimize(completion: (() -> Void)?) {
        let filteredParticles = model.capture.buffer.getMemoryRepresentationCopy(defaultValue: ParticleUniforms())
            .map({ particle -> ParticleUniforms in
                if particle.confidence < 0.20 {
                    return ParticleUniforms(color: Float3(0, 0, 1))
                }
                // How to actually change the size of this array if we always render the initial buffer
                return particle
            })
        model.capture.buffer.assign(with: filteredParticles)
        completion?()
    }
}

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
}
