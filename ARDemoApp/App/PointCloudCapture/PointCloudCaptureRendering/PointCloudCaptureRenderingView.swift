//
//  PointCloudCaptureRenderingView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import SwiftUI
import MetalKit
import ARKit

/// Helper for making PointCloudCaptureView available in SwiftUI.
struct PointCloudCaptureRenderingView: UIViewRepresentable {
    let controller: PointCloudCaptureRenderingController
    let metalDevice: MTLDevice

    init() {
        metalDevice = MTLCreateSystemDefaultDevice()!
        controller = PointCloudCaptureRenderingController(metalDevice: metalDevice)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PointCloudCaptureMTKView {
        let mtkView = PointCloudCaptureMTKView(device: metalDevice)

        // Need to setup the render destination a posteriori
        controller.renderDestination = mtkView
        // And then run the ARSession
        controller.startCapturing()

        mtkView.delegate = context.coordinator
        return mtkView
    }

    func updateUIView(_ uiView: PointCloudCaptureMTKView, context: Context) { }
}

// MARK: - Coordinator

extension PointCloudCaptureRenderingView {
    class Coordinator: NSObject, MTKViewDelegate {
        private let parent: PointCloudCaptureRenderingView

        init(_ parent: PointCloudCaptureRenderingView) {
            self.parent = parent
            super.init()
        }

        // MARK: MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            parent.controller.resizeDrawRect(to: size)
        }

        func draw(in view: MTKView) {
            parent.controller.draw()
        }
    }
}

// MARK: - Preview
struct PointCloudCaptureRenderingView_Previews: PreviewProvider {
    static var previews: some View {
        PointCloudCaptureRenderingView()
    }
}

// MARK: - Underlying UIKit View
final class PointCloudCaptureMTKView: MTKView {

    init(device: MTLDevice) {
        super.init(frame: .zero, device: device)

        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        // Enable depth test
        depthStencilPixelFormat = .depth32Float
        contentScaleFactor = 1

        // Continuously draw - maybe change that later
        isPaused = false
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
