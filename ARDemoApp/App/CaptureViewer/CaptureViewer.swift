//
//  CaptureViewer.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import Common
import PointCloudRendererService
import Combine

public struct CaptureViewer: View {

    @EnvironmentObject var particleBuffer: ParticleBufferWrapper

    public var body: some View {
        ZStack {
            SceneRender()

            VStack {

//                Metrics(currentPointCount: model.object.vertices.count,
//                        currentNormalCount: model.object.vertexNormals.count,
//                        currentFaceCount: model.object.triangles.count,
//                        activity: true)

                Spacer()

                CaptureViewerControl()
                    .environmentObject(CaptureViewerControlModel(particleBuffer: particleBuffer))
            }

        }
//        .onAppear {
////            sceneRenderingService.updatePointCloud(with: particleBuffer)
////            processorService.initialize(with: particleBuffer)
//
//        }
        .environmentObject(particleBuffer)
        .navigationBarTitle("Viewer", displayMode: .inline)
    }
}
