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
    @State private var scnFile = SCNFile()
    @State private var plyFile = PLYFile()
    @State private var showingExportActionSheet = false
    @State private var showingSCNExporter = false
    @State private var showingPLYExporter = false

    public init() { }

    var exportActionSheet: ActionSheet {
        ActionSheet(title: Text("Export Type"), message: Text("Supported export formats"), buttons: [
            .default(Text("SCN (Apple's SceneKit)"), action: {
                scnFile = viewModel.scnFile()
                showingSCNExporter = true
            }),
            .default(Text("PLY (Polygon File Format)"), action: {
                DispatchQueue.global(qos: .userInitiated).async {
                    plyFile = viewModel.plyFile()
                    DispatchQueue.main.async {
                        showingPLYExporter = true
                    }
                }
            }),
            .cancel()
        ])
    }

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
//                Button("Optimize") {
//                    plyFile = viewModel.plyFile()
//                    // then read with python and do processing and concert back etc
////                    plyFile.fileWrapper(configuration: )
////                    viewModel.optimize(completion: { viewModel.pointCloudProcessing = false })
//                }
//                .disabledConditionally(disabled: viewModel.pointCloudProcessing)

                ProgressView("Processing...")
                    .hiddenConditionally(isHidden: !viewModel.pointCloudProcessing)

                ProgressView("Exporting SCN...", value: scnFile.writeToDiskProgress, total: 1)
                    .hiddenConditionally(isHidden: !scnFile.writtingToDisk)
                    .fileExporter(isPresented: $showingSCNExporter,
                                  document: scnFile,
                                  contentType: .sceneKitScene,
                                  onCompletion: { _ in })

                ProgressView("Exporting PLY...", value: plyFile.writeToDiskProgress, total: 1)
                    .hiddenConditionally(isHidden: !plyFile.writtingToDisk)
                    .fileExporter(isPresented: $showingPLYExporter,
                                  document: plyFile,
                                  contentType: .polygon,
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
        .actionSheet(isPresented: $showingExportActionSheet, content: {
            exportActionSheet
        })
        .navigationBarTitle("Viewer", displayMode: .inline)
        .toolbar(content: {
            Button("Export") {
                showingExportActionSheet = true
            }
        })
    }
}
