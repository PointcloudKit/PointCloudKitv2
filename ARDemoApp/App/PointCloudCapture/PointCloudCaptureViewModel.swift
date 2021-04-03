//
//  PointCloudCaptureRenderingView+ViewModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import MetalKit
import PointCloudRendererService
import ARKit

import CaptureViewer

final class PointCloudCaptureViewModel: PointCloudCaptureRenderingViewDelegate, ObservableObject {

    @ObservedObject private var pointCloudRenderer: PointCloudRendererService

    @State private var sessionIsRunning: Bool = false
    @State private var isCapturing: Bool = false
    @State private var hasCapture: Bool = false
    @State private(set) var isShowingCoachingOverlay: Bool = false

    private let fileIOService = FileIO()

    /// Current number of point held in buffer
    @Published var currentPointCount: Int = 0

    public init() {
        pointCloudRenderer = PointCloudRendererService(metalDevice: MTLCreateSystemDefaultDevice()!)
        pointCloudRenderer.$currentPointCount
            .throttle(for: .milliseconds(100), scheduler: RunLoop.current, latest: true)
            .assign(to: &$currentPointCount)
    }

    // MARK: - Rendering Service Interface

    /// Generate the Model necessary to CaptureViewer View
    var captureViewerModel: CaptureViewerModel {
        CaptureViewerModel(capture: pointCloudRenderer.capture)
    }

    /// Initialize a new ARSession and start capturing (and flush current capture)
    func startSession() {
        assert(renderDestination != nil, "You have to set a renderDestination before starting a capture")

        sessionIsRunning = true
        isCapturing = false
        pointCloudRenderer.startSession()
    }

    /// Pause/Resume the ARSession to prevent ressource waste
    func pauseSession() {
        sessionIsRunning = false
        pointCloudRenderer.pauseSession()
    }
    func resumeSession() {
        sessionIsRunning = true
        pointCloudRenderer.resumeSession()
    }

    // Pause/Resume capture (accumulation of data)
    func pauseCapture() {
        isCapturing = false
        pointCloudRenderer.pauseCapture()
    }
    func resumeCapture() {
        isCapturing = true
        pointCloudRenderer.resumeCapture()
    }

    // MARK: - FileIOService Interface
    @discardableResult
    func writeToDisk(_ asset: MDLAsset) throws -> URL {
        let documentsPath = try fileIOService.documentFolderURL()
        let exportUrl = documentsPath.appendingPathComponent("test_\(asset.count).obj")

        print("writing asset to \(exportUrl)")
        try asset.export(to: exportUrl)
        return exportUrl
    }

}

// MARK: - PointCloudCaptureRenderingViewDelegate Conformance
extension PointCloudCaptureViewModel {

    /// The output where the rendering is done. Need to be set
    /// A bit convoluted... view's viewmodel own the Rendering service,
    /// but rendering service can only render once the view has loaded
    unowned var renderDestination: RenderDestinationProvider? {
        get {
            pointCloudRenderer.renderDestination
        }
        set {
            pointCloudRenderer.renderDestination = newValue
        }
    }

    var metalDevice: MTLDevice {
        pointCloudRenderer.device
    }

    var session: ARSession {
        pointCloudRenderer.session
    }

    func draw() {
        pointCloudRenderer.draw()
    }

    func resizeDrawRect(to size: CGSize) {
        pointCloudRenderer.resizeDrawRect(to: size)
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        isShowingCoachingOverlay = true
        pauseCapture()
        print("willActivate")
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        isShowingCoachingOverlay = false
        resumeCapture()
        print("didDeactivate")
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        startSession()
    }
}
