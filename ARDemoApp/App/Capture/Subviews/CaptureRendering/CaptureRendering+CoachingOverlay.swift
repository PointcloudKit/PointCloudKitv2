//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 3/4/2021.
//

import ARKit

// MARK: - `ARCoachingOverlayViewDelegate` protocol conformance
extension CaptureRendering: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        showCoachingOverlay = true
        renderingService.capturing = false

    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        showCoachingOverlay = false
        renderingService.capturing = true
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        renderingService.flush = true
    }
}
