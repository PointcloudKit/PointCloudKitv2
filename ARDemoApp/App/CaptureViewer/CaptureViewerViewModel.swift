//
//  CaptureViewerViewModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SceneKit
import PointCloudRendererService

final class CaptureViewerViewModel {

    func generateScene(from capture: PointCloudCapture) -> SCNScene {
        let scene = SCNScene()

        let positionVertex = PointCloudCapture.Vertex.position
        let colorVertex = PointCloudCapture.Vertex.color

        // Our data sources from Metal
        let positionSource = SCNGeometrySource(buffer: capture.buffer.rawBuffer,
                                               vertexFormat: positionVertex.format,
                                               semantic: positionVertex.semantic,
                                               vertexCount: capture.count,
                                               dataOffset: positionVertex.dataOffset,
                                               dataStride: capture.stride)

        let colorSource = SCNGeometrySource(buffer: capture.buffer.rawBuffer,
                                            vertexFormat: colorVertex.format,
                                            semantic: colorVertex.semantic,
                                            vertexCount: capture.count,
                                            dataOffset: colorVertex.dataOffset,
                                            dataStride: capture.stride)

        // What we want to generate
        let particles = SCNGeometryElement(data: nil,
                                           primitiveType: .point,
                                           primitiveCount: capture.count,
                                           bytesPerIndex: MemoryLayout<Int>.size)
        //        let elements = SCNGeometryElement(data: nil,
        //                                          primitiveType: .point,
//                                          primitiveCount: vertices.count,
//                                          bytesPerIndex: MemoryLayout<Int>.size)

        let pointCloudGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [particles])
        let pointCloudRootNode = SCNNode(geometry: pointCloudGeometry)
        scene.rootNode.addChildNode(pointCloudRootNode)
        return scene
    }
}
