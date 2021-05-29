//
//  CaptureControlModel.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 13/05/2021.
//

import Foundation
import PointCloudRendererService

final class CaptureControlModel: ObservableObject {

    @Published var renderingService: RenderingService

    lazy var captureParametersModel: CaptureParametersModel = CaptureParametersModel(renderingService: renderingService)
    lazy var captureViewerModel: CaptureViewerModel = CaptureViewerModel(renderingService: renderingService)
    lazy var toggleStyle: CaptureToggleStyle = CaptureToggleStyle()

    @Published var hasCaptureData: Bool = false

    init(renderingService: RenderingService) {
        self.renderingService = renderingService
        renderingService.$currentPointCount
            .map { $0 != 0 }
            .assign(to: &$hasCaptureData)
    }

    var capturing: Bool { renderingService.capturing }

    func pauseCapture() {
        renderingService.capturing = false
    }

    func flushCapture() {
        renderingService.flush = true
    }
}
