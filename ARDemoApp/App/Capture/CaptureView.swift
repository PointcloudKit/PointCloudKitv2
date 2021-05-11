//
//  CaptureView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import Common
import PointCloudRendererService

struct CaptureView: View {

    // MARK: - Owned

    @StateObject var renderingService = RenderingService(metalDevice: MTLCreateSystemDefaultDevice()!)

    @State var showCoachingOverlay = false
    @State var navigateToCaptureViewer = false

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(destination: CaptureViewerView(particleBuffer: renderingService.particleBufferWrapper,
                                                          initialCaptureParticleCount: renderingService.currentPointCount,
                                                          confidenceTreshold: renderingService.confidenceThreshold),
                               isActive: $navigateToCaptureViewer) { }

                CaptureRenderingView(renderingService: renderingService,
                                 showCoachingOverlay: $showCoachingOverlay)

                VStack {
                    MetricsView(currentPointCount: renderingService.currentPointCount,
                            currentNormalCount: 0,
                            currentFaceCount: 0,
                            activity: renderingService.capturing)

                    Spacer()

                    CaptureControlView(showCoachingOverlay: $showCoachingOverlay,
                                   navigateToCaptureViewer: $navigateToCaptureViewer)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.8))
                }
            }
            .background(Color.black)
            .statusBar(hidden: true)
            .navigationBarTitleDisplayMode(.automatic)
            .navigationTitle("Capture")
            .edgesIgnoringSafeArea(.bottom)
        }
        // For Ipad
        .navigationViewStyle(StackNavigationViewStyle())
        .onDisappear {
            renderingService.capturing = false
        }
        .environmentObject(renderingService)
    }
}
