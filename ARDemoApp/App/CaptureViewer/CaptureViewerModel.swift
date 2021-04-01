//
//  CaptureViewerModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import PointCloudRendererService

class CaptureViewerModel: ObservableObject {
    @Published var capture: PointCloudCapture

    init(capture: PointCloudCapture) {
        self.capture = capture
    }
}
