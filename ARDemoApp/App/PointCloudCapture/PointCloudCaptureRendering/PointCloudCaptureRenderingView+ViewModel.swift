//
//  PointCloudCaptureRenderingView+ViewModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import MetalKit

extension PointCloudCaptureRenderingView {
    final class ViewModel: ObservableObject {

        private let renderingService: PointCloudCaptureRenderingController

        let metalDevice: MTLDevice

        init() {
            metalDevice = MTLCreateSystemDefaultDevice()!
            renderingService = PointCloudCaptureRenderingController(metalDevice: metalDevice)
        }

        /// The output where the rendering is done. Need to be set
        var renderDestination: RenderDestinationProvider? = nil {
            didSet {
                renderingService.renderDestination = renderDestination
            }
        }

        // MARK: - Used by MTKView for drawing
        func draw() {
            renderingService.draw()
        }

        func resizeDrawRect(to size: CGSize) {
            renderingService.resizeDrawRect(to: size)
        }

        // MARK: - Interface
        func startCapture() {
            assert(renderDestination != nil, "You have to set a renderDestination before starting a capture")
            renderingService.startCapturing()
        }

        func stopCapture() {
            renderingService.stopCapturing()
        }
    }
}
