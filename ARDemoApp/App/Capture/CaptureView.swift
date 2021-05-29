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

    @EnvironmentObject var model: CaptureModel

    var body: some View {
        NavigationView {
            ZStack {

                CaptureRenderingView()
                    .environmentObject(model.captureRenderingModel)

                VStack {
                    MetricsView()
                        .environmentObject(model.metricsModel)

                    Spacer()

                    CaptureControlView()
                        .environmentObject(model.captureControlModel)
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
    }
}
