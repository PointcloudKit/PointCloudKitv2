//
//  CaptureRendering.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import SwiftUI
import MetalKit
import ARKit
import PointCloudRendererService

/// Helper for making Capture available in SwiftUI.
final class CaptureRendering: NSObject, UIViewRepresentable {

    // Cannot use the power of swiftUI here?
    unowned private(set) var renderingService: RenderingService

    private let coachingOverlay = ARCoachingOverlayView()

    @Binding var showCoachingOverlay: Bool

    public init(renderingService: RenderingService, showCoachingOverlay: Binding<Bool>) {
        self.renderingService = renderingService
        self._showCoachingOverlay = showCoachingOverlay
        super.init()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PointCloudCaptureMTKView {
        let mtkView = PointCloudCaptureMTKView(device: renderingService.device)

        // Need to setup the render destination a posteriori
        renderingService.renderDestination = mtkView
        mtkView.delegate = context.coordinator

        // Setup coaching overlay
        #if !targetEnvironment(simulator)
        coachingOverlay.session = renderingService.session
        #endif
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .tracking

        // Add coaching overlay
        mtkView.addSubview(coachingOverlay)
        coachingOverlay.delegate = self
        coachingOverlay.didMoveToSuperview()
        coachingOverlay.setActive(true, animated: true)

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
