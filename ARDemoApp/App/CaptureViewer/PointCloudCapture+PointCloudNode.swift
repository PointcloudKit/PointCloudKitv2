//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import SceneKit
import PointCloudRendererService
import Common
import Combine

extension PointCloudCapture {

    private static let positionVertex = PointCloudCapture.Component.position
    private static let colorVertex = PointCloudCapture.Component.color
    // private static let confidence = PointCloudCapture.Component.confidence

    public func generatePointCloudNode() -> Future<(SCNNode, vertexCount: Int), Never> {
        Future { promise in
            /* * */ let start = DispatchTime.now()
            let rawBuffer = buffer.rawBuffer
            let dataStride = stride
            let vertexCount = count

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

            promise(.success((pointCloudRootNode, vertexCount: vertexCount)))
            /* * */ let end = DispatchTime.now()
            /* * */ let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            /* * */ print(" <*> Time to run \(#function): \(Double(nanoTime) / 1_000_000) ms")
        }
    }
}
