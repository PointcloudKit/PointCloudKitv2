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

    let particleBuffer: ParticleBufferWrapper

    @Published var particleCount: Int = 0
    @Published var scene: SCNScene = SCNScene()
    @Published var rendering = false

    init(particleBuffer: ParticleBufferWrapper, initialParticleCount: Int) {
        self.particleBuffer = particleBuffer

        initializeScene()
        updateScene(particleCount: initialParticleCount)
    }

    lazy var ambientLightNode: SCNNode = {
        let ambientLightNode = SCNNode()
        let light = SCNLight()

        light.type = .ambient
        ambientLightNode.light = light
        return ambientLightNode
    }()

    lazy var cameraNode: SCNNode = {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.name = NodeIdentifier.camera.rawValue
        return cameraNode
    }()

    private func initializeScene() {
        scene.rootNode.addChildNode(ambientLightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.background.contents = UIColor.black
    }

    func updateScene(particleCount: Int) {
        rendering = true
        self.particleCount = particleCount
        pointCloudNode(from: particleBuffer)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pointCloudRootNode in
                defer { self?.rendering = false }
                guard let self = self else { return }
                // Remove existing if any
                self.scene.rootNode
                    .childNode(withName: NodeIdentifier.pointCloudRoot.rawValue, recursively: false)?
                    .removeFromParentNode()
                // Add new pointCloudNode
                self.scene.rootNode.addChildNode(pointCloudRootNode)
                // Adjust camera
                self.cameraNode.look(at: pointCloudRootNode.position)
                self.cameraNode.position.z += 5
            }
            .store(in: &cancellables)
    }

    private static let positionVertex = ParticleBufferWrapper.Component.position
    private static let colorVertex = ParticleBufferWrapper.Component.color
    // private static let confidence = ParticleBuffer.Component.confidence

    private func pointCloudNode(from particleBuffer: ParticleBufferWrapper) -> Future<SCNNode, Never> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                /* * */ let start = DispatchTime.now()
                let rawBuffer = particleBuffer.buffer.rawBuffer
                let dataStride = particleBuffer.stride
                let vertexCount = self.particleCount

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

struct SceneRender: View {

    @EnvironmentObject var model: SceneRenderModel

    public var body: some View {
        ZStack {
            SceneView(scene: model.scene,
                      pointOfView: model.cameraNode,
                      options: [.allowsCameraControl,
                                .autoenablesDefaultLighting])

            if model.rendering {
                ProgressView("Rendering...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.bone)
            }
        }
    }
}
