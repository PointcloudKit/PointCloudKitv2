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

    @StateObject var model = CaptureViewerModel()

    let particleBuffer: ParticleBufferWrapper
    let initialCaptureParticleCount: Int
    let confidenceTreshold: ConfidenceTreshold

    @State var object: Object3D = Object3D()

    public var body: some View {
        ZStack {
            SceneView(scene: model.updatedScene(using: particleBuffer, particleCount: object.vertices.count),
                      pointOfView: model.cameraNode,
                      options: [.allowsCameraControl,
                                .autoenablesDefaultLighting,
                                .rendersContinuously])

            VStack {

                MetricsView(currentPointCount: object.vertices.count,
                        currentNormalCount: object.vertexNormals.count,
                        currentFaceCount: object.triangles.count,
                        activity: true)

                Spacer()

                CaptureViewerControlsView(particleBuffer: particleBuffer,
                                     object: $object,
                                     confidenceTreshold: confidenceTreshold)
                    .environmentObject(model.captureViewerControlModel)
                    .padding(.bottom, 20)
                    .background(Color.black.opacity(0.8))
            }

        }
        .navigationBarTitle("Viewer", displayMode: .inline)
        .onAppear {
            CaptureViewerModel.convert(particleBuffer, particleCount: initialCaptureParticleCount)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { object in
                    self.object = object
                })
                .store(in: &model.cancellables)
        }
        .onDisappear {
            model.cancellables.forEach { cancellable in cancellable.cancel() }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
