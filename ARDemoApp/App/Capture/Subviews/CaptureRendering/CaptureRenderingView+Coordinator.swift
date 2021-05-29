//
//  CaptureRenderingView+Coordinator.swift
//  
//
//  Created by Alexandre Camilleri on 30/03/2021.
//

import SwiftUI
import MetalKit
import ARKit

// MARK: - Coordinator

extension CaptureRenderingView {
    class Coordinator: NSObject, MTKViewDelegate {
        private(set) var parent: CaptureRenderingView

        init(_ parent: CaptureRenderingView) {
            self.parent = parent
            super.init()
        }

        // MARK: - MTKViewDelegate conformance

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            parent.model.resizeDrawRect(to: size)
        }

        func draw(in view: MTKView) {
            parent.model.draw()
        }
    }
}

// MARK: - `ARCoachingOverlayViewDelegate` protocol conformance
extension CaptureRenderingView.Coordinator: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        parent.model.coachingOverlayStatusUpdate(to: .activated)
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        parent.model.coachingOverlayStatusUpdate(to: .deactivated)
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        parent.model.flushCapture()
    }
}
