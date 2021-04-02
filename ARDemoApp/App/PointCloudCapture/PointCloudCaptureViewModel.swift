//
//  PointCloudCaptureRenderingView+ViewModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import MetalKit
import PointCloudRendererService

final class PointCloudCaptureViewModel: PointCloudCaptureRenderingViewDelegate, ObservableObject {

    @ObservedObject private var pointCloudRenderer: PointCloudRendererService

    private let fileIOService = FileIO()

    /// Current number of point held in buffer
    @Published var currentPointCount: Int = 0

    public init() {
        pointCloudRenderer = PointCloudRendererService(metalDevice: MTLCreateSystemDefaultDevice()!)
        pointCloudRenderer.$currentPointCount.assign(to: &$currentPointCount)
    }

    // MARK: - Rendering Service Interface

    /// Generate the Model necessary to AssetViewer View
    var assetViewerModel: CaptureViewerModel {
        CaptureViewerModel(capture: pointCloudRenderer.capture)
    }

    func startCapture() {
        assert(renderDestination != nil, "You have to set a renderDestination before starting a capture")
        pointCloudRenderer.pauseSession()
        pointCloudRenderer.startSession()
    }

    func pauseCapture() {
        pointCloudRenderer.pauseCapture()
    }

    func flushCapture() {
        pointCloudRenderer.pauseCapture()
        pointCloudRenderer.pauseSession()
        pointCloudRenderer.flushBuffers()
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

    func draw() {
        pointCloudRenderer.draw()
    }

    func resizeDrawRect(to size: CGSize) {
        pointCloudRenderer.resizeDrawRect(to: size)
    }
}
