//
//  PointCloudCaptureRenderingView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import SwiftUI
import MetalKit
import ARKit

public protocol PointCloudCaptureRenderingViewDelegate: AnyObject {
    var metalDevice: MTLDevice { get }
    var renderDestination: RenderDestinationProvider? { get set }
    var session: ARSession { get }
    func draw()
    func resizeDrawRect(to size: CGSize)
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView)
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView)
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView)
}

/// Helper for making PointCloudCaptureView available in SwiftUI.
public final class PointCloudCaptureRenderingView: NSObject, UIViewRepresentable {

    unowned var renderingDelegate: PointCloudCaptureRenderingViewDelegate

    public let coachingOverlay: ARCoachingOverlayView

    public init(renderingDelegate: PointCloudCaptureRenderingViewDelegate) {
        self.renderingDelegate = renderingDelegate
        coachingOverlay = Self.coachingOverlayView(using: renderingDelegate.session)
        super.init()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> PointCloudCaptureMTKView {
        let mtkView = PointCloudCaptureMTKView(device: renderingDelegate.metalDevice)

        // Need to setup the render destination a posteriori
        renderingDelegate.renderDestination = mtkView
        mtkView.delegate = context.coordinator

        // Add coaching overlay
        mtkView.addSubview(coachingOverlay)
        coachingOverlay.delegate = self
        coachingOverlay.didMoveToSuperview()
        coachingOverlay.setActive(true, animated: true)

        return mtkView
    }

    public func updateUIView(_ uiView: PointCloudCaptureMTKView, context: Context) { }
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
