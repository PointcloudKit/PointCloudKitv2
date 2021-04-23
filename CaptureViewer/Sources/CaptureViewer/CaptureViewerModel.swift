//
//  CaptureViewerModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import Combine
import PointCloudRendererService
import PointCloudProcessorService

enum NodeIdentifier: String {
    case camera = "com.pointCloudKit.nodes.camera"
    case pointCloudRoot = "com.pointCloudKit.nodes.pointCloudRootRoot"
}

final public class CaptureViewerModel: ObservableObject {
    private(set) var capture: PointCloudCapture
    public var processorParameters: ProcessorParameters

    public init(capture: PointCloudCapture) {
        self.capture = capture
        processorParameters = ProcessorParameters.fromUserDefaultOrNew
    }

    deinit {
        processorParameters.writeToUserDefault()
    }
}
