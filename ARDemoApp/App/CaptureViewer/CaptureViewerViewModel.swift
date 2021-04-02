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

        let positionVertex = PointCloudCapture.Component.position
        let colorVertex = PointCloudCapture.Component.color
        let confidence = PointCloudCapture.Component.confidence

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
        scene.rootNode.addChildNode(pointCloudRootNode)
        return scene
    }
}
