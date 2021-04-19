//
//  AssetViewer.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import SceneKit
import PointCloudRendererService
import Common

public struct CaptureViewer: View {

    @EnvironmentObject var viewModel: CaptureViewerViewModel

    @State private var optimizingPointCloud = false
    @State private var scnExportFile = SCNFile()
    @State private var showingSCNExporter = false

    public init() { }

    public var body: some View {
        ZStack {
            SceneView(scene: viewModel.scene,
                      pointOfView: viewModel.cameraNode,
                      options: [
                        .rendersContinuously,
                        .allowsCameraControl,
                        .autoenablesDefaultLighting,
                        .temporalAntialiasingEnabled
                      ])

            VStack {

                Spacer()
                    // Point Cloud processing control block -- todo
                    Button("Optimize") {
                        viewModel.optimize(completion: { viewModel.pointCloudProcessing = false })
                    }
                    .disabledConditionally(disabled: viewModel.pointCloudProcessing)

                ProgressView("Processing...")
                    .hiddenConditionally(isHidden: !viewModel.pointCloudProcessing)

                ProgressView("Exporting...", value: scnExportFile.writeToDiskProgress, total: 1)
                    .hiddenConditionally(isHidden: !scnExportFile.writtingToDisk)
                    .fileExporter(isPresented: $showingSCNExporter,
                                  document: scnExportFile,
                                  contentType: .sceneKitScene,
                                  onCompletion: { _ in })

                HStack(alignment: .top, spacing: 0, content: {
                    Label(
                        title: { Text("\(viewModel.vertexCount)") },
                        icon: {
                            Image(systemName: "aqi.medium")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    )
                    .padding()

                    Spacer()
                })
            }
        }
        .navigationBarTitle("Viewer", displayMode: .inline)
        .toolbar(content: {
            Button("Export") {
                scnExportFile = SCNFile(scene: viewModel.scene)
                showingSCNExporter = true
            }
        })
    }
}
