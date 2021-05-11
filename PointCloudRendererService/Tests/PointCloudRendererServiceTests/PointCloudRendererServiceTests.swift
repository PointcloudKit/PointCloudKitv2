import XCTest
@testable import PointCloudRendererService

final class PointCloudRendererServiceTests: XCTestCase {
    func testExample() {
        let pointCloudRendererService = RenderingService(metalDevice: MTLCreateSystemDefaultDevice()!)

        // CaptureRenderingView' View Model
        let viewModel = CaptureRendering.ViewModel(renderingService: pointCloudRenderingService)
        let view = CaptureRendering(viewModel: viewModel)

    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
