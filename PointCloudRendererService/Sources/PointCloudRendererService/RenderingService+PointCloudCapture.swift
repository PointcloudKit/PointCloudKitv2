//
//  RenderingService+Asset.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

extension RenderingService {
    public func generateCapture() -> PointCloudCapture {
        PointCloudCapture(buffer: particlesBuffer,
                          count: currentPointCount,
                          confidenceTreshold: confidenceThreshold)
    }
}
