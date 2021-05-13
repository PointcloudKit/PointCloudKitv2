//
//  CaptureRenderingView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import SwiftUI
import MetalKit
import ARKit
import PointCloudRendererService

struct CaptureRenderingView: UIViewRepresentable {

    @EnvironmentObject var model: CaptureRenderingModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PointCloudCaptureMTKView {
        let mtkView = PointCloudCaptureMTKView(device: model.device)

        // Need to setup the render destination a posteriori
        model.setRenderDestination(to: mtkView)
        mtkView.delegate = context.coordinator

        // Setup coaching overlay
        model.coachingOverlay.removeFromSuperview()
        #if !targetEnvironment(simulator)
        model.coachingOverlay.session = model.session
        #endif
        model.coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        model.coachingOverlay.goal = .tracking

        // Add coaching overlay
        mtkView.addSubview(model.coachingOverlay)
        model.coachingOverlay.delegate = context.coordinator
        model.coachingOverlay.didMoveToSuperview()
        model.coachingOverlay.setActive(true, animated: true)

        return mtkView
    }

    func updateUIView(_ uiView: PointCloudCaptureMTKView, context: Context) { }
}

// MARK: - Underlying UIKit View
final public class PointCloudCaptureMTKView: MTKView {

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
