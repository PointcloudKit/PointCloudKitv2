//
//  CaptureModel.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 12/05/2021.
//

import SwiftUI
import Common
import PointCloudRendererService

final class CaptureModel: ObservableObject {
    @Published var renderingService: RenderingService

    let metricsModel: MetricsModel
    let captureControlModel: CaptureControlModel
    let captureRenderingModel: CaptureRenderingModel

    init(renderingService: RenderingService) {
        self.renderingService = renderingService
        captureControlModel = CaptureControlModel(renderingService: renderingService)
        captureRenderingModel = CaptureRenderingModel(renderingService: renderingService)
        metricsModel = MetricsModel()

        renderingService.$currentPointCount.assign(to: &metricsModel.$currentPointCount)
        renderingService.$capturing.assign(to: &metricsModel.$activity)
    }

    func pauseCapture() {
        renderingService.capturing = false
    }
}
