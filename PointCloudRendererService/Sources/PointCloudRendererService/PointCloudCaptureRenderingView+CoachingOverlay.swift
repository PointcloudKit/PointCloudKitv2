//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 3/4/2021.
//

import ARKit

extension PointCloudCaptureRenderingView {
    class func coachingOverlayView(using session: ARSession) -> ARCoachingOverlayView {
        let coachingOverlay = ARCoachingOverlayView()
        #if !targetEnvironment(simulator)
        coachingOverlay.session = session
        #endif
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .tracking

        return coachingOverlay
    }
}

// MARK: - `ARCoachingOverlayViewDelegate` protocol conformance
extension PointCloudCaptureRenderingView: ARCoachingOverlayViewDelegate {
    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        renderingDelegate.coachingOverlayViewWillActivate(coachingOverlayView)
    }

    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        renderingDelegate.coachingOverlayViewDidDeactivate(coachingOverlayView)
    }

    public func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        renderingDelegate.coachingOverlayViewDidRequestSessionReset(coachingOverlayView)
    }
}
