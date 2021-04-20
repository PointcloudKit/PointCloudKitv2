//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 30/03/2021.
//

import SwiftUI
import MetalKit
import ARKit

// MARK: - Coordinator

extension PointCloudCaptureRenderingView {
    public class Coordinator: NSObject, MTKViewDelegate {
        private let parent: PointCloudCaptureRenderingView

        init(_ parent: PointCloudCaptureRenderingView) {
            self.parent = parent
            super.init()
        }
    }
}

// MARK: - MTKViewDelegate conformance
extension PointCloudCaptureRenderingView.Coordinator {

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        parent.renderingDelegate.resizeDrawRect(to: size)
    }

    public func draw(in view: MTKView) {
        parent.renderingDelegate.draw()
    }
}
