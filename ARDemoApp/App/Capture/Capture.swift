//
//  Capture.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import Common
import PointCloudRendererService

final class CaptureModel: ObservableObject {

    @Published var renderingService = RenderingService(metalDevice: MTLCreateSystemDefaultDevice()!)

}

struct Capture: View {

    // MARK: - Owned

    @EnvironmentObject var model: CaptureModel

    @State var showCoachingOverlay = false
    @State var navigateToCaptureViewer = false

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(destination: CaptureViewer()
                                .environmentObject(CaptureViewerModel(particleBuffer: model.renderingService.particleBufferWrapper,
                                                                      particleCount: model.renderingService.currentPointCount,
                                                                      confidenceTreshold: model.renderingService.confidenceThreshold)),
                               isActive: $navigateToCaptureViewer) { }

                CaptureRendering(renderingService: model.renderingService,
                                 showCoachingOverlay: $showCoachingOverlay)

                VStack {
                    Metrics(currentPointCount: model.renderingService.currentPointCount,
                            currentNormalCount: 0,
                            currentFaceCount: 0,
                            activity: model.renderingService.capturing)

                    Spacer()

                    CaptureControl(showCoachingOverlay: $showCoachingOverlay,
                                   navigateToCaptureViewer: $navigateToCaptureViewer)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.8))
                        .environmentObject(model.renderingService)
                }
            }
            .background(Color.black)
            .statusBar(hidden: true)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Capture")
            .edgesIgnoringSafeArea(.bottom)
        }
        .onDisappear {
            model.renderingService.capturing = false
        }
    }
}
