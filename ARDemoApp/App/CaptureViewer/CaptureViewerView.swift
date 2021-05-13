//
//  CaptureViewerView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import Common
import PointCloudRendererService
import Combine
import SceneKit

struct CaptureViewerView: View {

    @EnvironmentObject var model: CaptureViewerModel

    public var body: some View {
        ZStack {
            SceneView(scene: model.scene,
                      pointOfView: model.cameraNode,
                      options: [.allowsCameraControl,
                                .autoenablesDefaultLighting,
                                .rendersContinuously])

            VStack {
                MetricsView()
                    .environmentObject(model.metricsModel)

                Spacer()

                CaptureViewerControlsView(object: $model.object)
                    .environmentObject(model.captureViewerControlModel)
                    .padding(.bottom, 20)
                    .background(Color.black.opacity(0.8))
            }

        }
        .navigationBarTitle("Viewer", displayMode: .inline)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            // This convert the initial particle buffer into the first Object3D, triggering initial render.
            model.generateFirstObjectFromParticleBuffer()
        }
    }
}
