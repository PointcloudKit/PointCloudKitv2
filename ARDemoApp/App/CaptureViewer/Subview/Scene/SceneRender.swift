//
//  CaptureViewerScene.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 03/05/2021.
//

import SwiftUI
import SceneKit
import Common
import PointCloudRendererService
import Combine

enum NodeIdentifier: String {
    case camera = "com.pointCloudKit.nodes.camera"
    case pointCloudRoot = "com.pointCloudKit.nodes.pointCloudRootRoot"
}

final class SceneRenderModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

struct SceneRender: View {

    let model = SceneRenderModel()

    let particleBuffer: ParticleBufferWrapper
    let particleCount: Int

    @State var rendering = false

    var scene: SCNScene {
        let scene = SCNScene()
        let cameraNode = SCNNode()

        cameraNode.camera = SCNCamera()
        cameraNode.name = NodeIdentifier.camera.rawValue

        scene.rootNode.addChildNode(ambientLightNode)
        scene.background.contents = UIColor.black

        pointCloudNode(from: particleBuffer)
            .receive(on: DispatchQueue.main)
            .sink { pointCloudRootNode in
                // Add new pointCloudNode
                scene.rootNode.addChildNode(pointCloudRootNode)
                // Adjust camera
                cameraNode.look(at: pointCloudRootNode.position)
                cameraNode.position.z += 5
                scene.rootNode.addChildNode(cameraNode)
            }
            .store(in: &model.cancellables)

        return scene
    }

    var ambientLightNode: SCNNode {
        let ambientLightNode = SCNNode()
        let light = SCNLight()

        light.type = .ambient
        ambientLightNode.light = light
        return ambientLightNode
    }

    public var body: some View {
        let scene = scene

        ZStack {
            SceneView(scene: scene,
                      pointOfView: scene.rootNode.childNode(withName: NodeIdentifier.camera.rawValue,
                                                            recursively: false),
                      options: [.allowsCameraControl,
                                .autoenablesDefaultLighting])

            if rendering {
                ProgressView("Rendering...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.bone)
            }
        }
    }
}

extension SceneRender {

    private static let positionVertex = ParticleBufferWrapper.Component.position
    private static let colorVertex = ParticleBufferWrapper.Component.color
    // private static let confidence = ParticleBuffer.Component.confidence

    private func pointCloudNode(from particleBuffer: ParticleBufferWrapper) -> Future<SCNNode, Never> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                /* * */ let start = DispatchTime.now()
                let rawBuffer = particleBuffer.buffer.rawBuffer
                let dataStride = particleBuffer.stride
                let vertexCount = particleCount

                // Our data sources from Metal
                let positionSource = SCNGeometrySource(buffer: rawBuffer,
                                                       vertexFormat: Self.positionVertex.format,
                                                       semantic: Self.positionVertex.semantic,
                                                       vertexCount: vertexCount,
                                                       dataOffset: Self.positionVertex.dataOffset,
                                                       dataStride: dataStride)

                let colorSource = SCNGeometrySource(buffer: rawBuffer,
                                                    vertexFormat: Self.colorVertex.format,
                                                    semantic: Self.colorVertex.semantic,
                                                    vertexCount: vertexCount,
                                                    dataOffset: Self.colorVertex.dataOffset,
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

                promise(.success(pointCloudRootNode))
                /* * */ let end = DispatchTime.now()
                /* * */ let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                /* * */ print(" <*> SceneRenderer - Generate SCNNode from particleBuffer \(#function): \(Double(nanoTime) / 1_000_000) ms")
            }
        }
    }
}
