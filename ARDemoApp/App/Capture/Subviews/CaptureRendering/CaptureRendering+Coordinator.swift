//
//  CaptureRendering+Coordinator.swift
//  
//
//  Created by Alexandre Camilleri on 30/03/2021.
//

import SwiftUI
import MetalKit
import ARKit

// MARK: - Coordinator

extension CaptureRendering {
    class Coordinator: NSObject, MTKViewDelegate {
        private(set) var parent: CaptureRendering

        init(_ parent: CaptureRendering) {
            self.parent = parent
            super.init()
        }

        // MARK: - MTKViewDelegate conformance

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            parent.renderingService.resizeDrawRect(to: size)
        }

        func draw(in view: MTKView) {
            parent.renderingService.draw()
        }
    }
}
