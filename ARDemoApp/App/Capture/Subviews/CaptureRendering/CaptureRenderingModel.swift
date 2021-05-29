//
//  CaptureRenderingModel.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 13/05/2021.
//

import MetalKit
import ARKit
import PointCloudRendererService

final class CaptureRenderingModel: ObservableObject {

    enum CoachingOverlayStatus {
        case activated, deactivated
    }

    unowned private let renderingService: RenderingService

    let coachingOverlay = ARCoachingOverlayView()

    init(renderingService: RenderingService) {
        self.renderingService = renderingService
    }

    var device: MTLDevice { renderingService.device }
    var session: ARSession { renderingService.session }

    func coachingOverlayStatusUpdate(to status: CoachingOverlayStatus) {
        if status == .activated {
            renderingService.capturing = false
        }
        if status == .deactivated {
            if renderingService.currentPointCount == 0 {
                renderingService.capturing = true
            }
        }
    }

    func flushCapture() {
        renderingService.flush = true
    }

    func setRenderDestination(to view: MTKView) {
        renderingService.renderDestination = view
    }

    func draw() {
        renderingService.draw()
    }

    func resizeDrawRect(to size: CGSize) {
        renderingService.resizeDrawRect(to: size)
    }
}
