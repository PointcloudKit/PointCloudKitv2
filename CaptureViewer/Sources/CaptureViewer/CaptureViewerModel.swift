//
//  CaptureViewerModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import PointCloudRendererService

public class CaptureViewerModel: ObservableObject {
    let capture: PointCloudCapture

    public init(capture: PointCloudCapture) {
        self.capture = capture
    }
}
