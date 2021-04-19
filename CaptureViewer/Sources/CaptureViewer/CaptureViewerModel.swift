//
//  CaptureViewerModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import PointCloudRendererService
import PointCloudProcessorService

enum NodeIdentifier: String {
    case camera = "com.pointCloudKit.nodes.camera"
    case pointCloudRoot = "com.pointCloudKit.nodes.pointCloudRootRoot"
}

public class CaptureViewerModel: ObservableObject {
    private(set) var capture: PointCloudCapture

    public init(capture: PointCloudCapture) {
        self.capture = capture
    }
}
