//
//  CaptureViewerModel.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 06/05/2021.
//

import Foundation
import SceneKit
import PointCloudRendererService
import Combine
import Common

enum NodeIdentifier: String {
    case camera = "com.pointCloudKit.nodes.camera"
    case pointCloudRoot = "com.pointCloudKit.nodes.pointCloudRootRoot"
}

final class CaptureViewerModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()

    let captureViewerControlModel = CaptureViewerControlModel(processorService: ProcessorService(), exportService: ExportService())

    private let scene = SCNScene()
    let cameraNode = SCNNode()
    var pointCloudNode: SCNNode?

    // MARK: - PointCloudKit -> PointCloudKit
    class func convert(_ particleBuffer: ParticleBufferWrapper, particleCount: Int) -> Future<Object3D, Never> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                let particles = particleBuffer.buffer.getMemoryRepresentationCopy(for: particleCount)
                let object = Object3D(vertices: particles.map(\.position),
                                      vertexConfidence: particles.map({ particle in UInt(particle.confidence) }),
                                      vertexColors: particles.map(\.color))
                promise(.success(object))
            }
        }
    }

    init() {
        cameraNode.camera = SCNCamera()
        cameraNode.name = NodeIdentifier.camera.rawValue
        cameraNode.position.z += 5
        scene.rootNode.addChildNode(cameraNode)

        let ambientLightNode = SCNNode()
        let light = SCNLight()
        light.type = .ambient
        ambientLightNode.light = light
        scene.rootNode.addChildNode(ambientLightNode)

        scene.background.contents = UIColor.black
    }

    func updatedScene(using particleBuffer: ParticleBufferWrapper, particleCount: Int) -> SCNScene {
        pointCloudNode(from: particleBuffer, particleCount: particleCount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pointCloudRootNode in
                guard let self = self else { return }
                self.pointCloudNode?.removeFromParentNode()
                self.pointCloudNode = pointCloudRootNode
                // Add new pointCloudNode
                self.scene.rootNode.addChildNode(pointCloudRootNode)
                // Adjust camera
                self.cameraNode.look(at: pointCloudRootNode.position)
            }
            .store(in: &cancellables)

        return scene
    }
}

extension CaptureViewerModel {

    private static let positionVertex = ParticleBufferWrapper.Component.position
    private static let colorVertex = ParticleBufferWrapper.Component.color
    // private static let confidence = ParticleBuffer.Component.confidence

    private func pointCloudNode(from particleBuffer: ParticleBufferWrapper, particleCount: Int) -> Future<SCNNode, Never> {
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
                /* * */ print(" <*> CaptureViewerModel - Generate SCNNode from particleBuffer \(#function): \(Double(nanoTime) / 1_000_000) ms")
            }
        }
    }
}
