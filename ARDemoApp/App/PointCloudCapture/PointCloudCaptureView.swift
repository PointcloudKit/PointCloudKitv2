//
//  PointCloudCaptureView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import SwiftUI
import MetalKit
import ARKit

struct PointCloudCaptureView: UIViewRepresentable {
    typealias UIViewType = MTKView

    private let session = ARSession()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        let device = context.coordinator.metalDevice

        mtkView.delegate = context.coordinator
        mtkView.device = device
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size

        // Enable depth test
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.contentScaleFactor = 1

        mtkView.delegate = context.coordinator
        session.delegate = context.coordinator

        context.coordinator.renderer = PointCloudRenderer(session: session,
                                                          metalDevice: device,
                                                          renderDestination: mtkView)

        // Create a world-tracking configuration, and
        // enable the scene depth frame-semantic.
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth

        // Run the view's session
        session.run(configuration)

        mtkView.isPaused = false

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) { }

    class Coordinator: NSObject, MTKViewDelegate, ARSessionDelegate {
        var parent: PointCloudCaptureView
        var metalDevice: MTLDevice

        var renderer: PointCloudRenderer!

        init(_ parent: PointCloudCaptureView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            } else {
                fatalError("No Metal device available")
            }
            super.init()
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer.resizeDrawRect(to: size)
        }

        func draw(in view: MTKView) {
            renderer.draw()
        }

        // MARK: - ARSessionDelegate

        func session(_ session: ARSession, didFailWithError error: Error) {
            print("ARSession error")
        }
    }
}
