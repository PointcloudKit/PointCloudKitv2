import XCTest
@testable import PointCloudRendererService

final class PointCloudRendererServiceTests: XCTestCase {
    func testExample() {
        let pointCloudRendererService = PointCloudRendererService(metalDevice: MTLCreateSystemDefaultDevice()!)

        // PointCloudCaptureRenderingView' View Model
        let viewModel = PointCloudCaptureRenderingView.ViewModel(renderingService: pointCloudRenderingService)
        let view = PointCloudCaptureRenderingView(viewModel: viewModel)

    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
