//
//  AssetViewer.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import SceneKit
import Common

public struct CaptureViewer: View {

    @EnvironmentObject var viewModel: CaptureViewerViewModel

    @State private var optimizingPointCloud = false
    @State private var scnFile = SCNFile()
    @State private var plyFile = PLYFile()
    @State private var showingExportActionSheet = false
    @State private var showingSCNExporter = false
    @State private var showingPLYExporter = false
    // Main Parameters view
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false

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

    // MARK: - Paramters

    var transformingParameters: some View {
        HStack {
            Label(
                title: { Text(">").foregroundColor(.white) },
                icon: {
                    Image(systemName: "wand.and.stars")
                        .font(.body)
                        .foregroundColor(.white)
                }
            )

            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack {
                    // MARK: Surface Reconstruction
                    Button(action: {
                        print("test")
                        //                        viewModel.surfaceReconstruction()
                    }, label: {
                        Label(
                            title: { Text("Surface Reconstruction").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "skew")
                                    .font(.body)
                                    .foregroundColor(!viewModel.pointCloudProcessing ? .red : .gray)
                            }
                        )
                    })
                    .disabled(viewModel.pointCloudProcessing)
                }
            })
        }
    }

    var cleaningParameters: some View {
        HStack {
            Label(
                title: { Text(">").foregroundColor(.white) },
                icon: {
                    Image(systemName: "scissors")
                        .font(.body)
                        .foregroundColor(.white)
                }
            )

            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack {
                    // MARK: Voxel DownSampling
                    Button(action: {
                        viewModel.voxelDownsampling()
                    }, label: {
                        Label(
                            title: { Text("Voxel Filtering").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "cube")
                                    .font(.body)
                                    .foregroundColor(!viewModel.pointCloudProcessing ? .red : .gray)
                            }
                        )
                    })
                    .disabled(viewModel.pointCloudProcessing)

                    // MARK: Statistical Outlier Removal
                    Button(action: {
                        viewModel.statisticalOutlierRemoval()
                    }, label: {
                        Label(
                            title: { Text("Statistical O.R.").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "aqi.high")
                                    .font(.body)
                                    .foregroundColor(!viewModel.pointCloudProcessing ? .red : .gray)
                            }
                        )
                    })
                    .disabled(viewModel.pointCloudProcessing)

                    // MARK: Radius Outlier Removal
                    Button(action: {
                        viewModel.radiusOutlierRemoval()
                    }, label: {
                        Label(
                            title: { Text("Radius O.R.").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "aqi.medium")
                                    .font(.body)
                                    .foregroundColor(!viewModel.pointCloudProcessing ? .red : .gray)
                            }
                        )
                    })
                    .disabled(viewModel.pointCloudProcessing)
                }
            })
        }
    }

    var genericParameters: some View {
        HStack {
            Label(
                title: { Text(">").foregroundColor(.white) },
                icon: {
                    Image(systemName: "gearshape.2.fill")
                        .font(.body)
                        .foregroundColor(.white)
                }
            )

            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack {
                    // MARK: Undo
                    Button(action: {
                        viewModel.undo()
                    }, label: {
                        Label(
                            title: { Text("Undo").foregroundColor(viewModel.undoAvailable ? .white : .gray) },
                            icon: {
                                Image(systemName: "arrow.uturn.backward.square")
                                    .font(.body)
                                    .foregroundColor(!viewModel.undoAvailable || !viewModel.pointCloudProcessing ? .red : .gray)
                            }
                        )
                    })
                    .disabled(!viewModel.undoAvailable || viewModel.pointCloudProcessing)
                }
            })
        }
    }

    // MARK: - Controls of the view
    var controlsSection: some View {
        HStack {

            Button(action: {
                withAnimation {
                    showParameters.toggle()
                }
            }, label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 42, weight: .regular))
                    .scaleEffect(showParameters ? 0.9 : 1)
                    .foregroundColor(showParameters ? .red : .white)
            })

            Spacer()

            Button(action: {
                withAnimation {
                    showingExportActionSheet = true
                }
            }, label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(showParameters || viewModel.pointCloudProcessing ? .gray : .white)
            })
            .disabled(showParameters || viewModel.pointCloudProcessing)
        }
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

                // Metrics
                MetricsView(currentPointCount: $viewModel.vertexCount)

                Spacer()

                ProgressView("Rendering...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .hiddenConditionally(isHidden: !viewModel.pointCloudRendering)

                ProgressView("Processing...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
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

                // Parameters
                VStack {

                    // Toggleable parameters list from the Controls section left bottom button
                    if showParameters {
                        transformingParameters
                            .padding(.horizontal, 20)
                            .transition(.moveAndFade)
                        cleaningParameters
                            .padding(.horizontal, 20)
                            .transition(.moveAndFade)
                        genericParameters
                            .padding(.horizontal, 20)
                            .transition(.moveAndFade)
                    }

                    // Controls Section at the bottom of the screen
                    controlsSection
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }
                .background(Color.black.opacity(0.8))

            }
        }
        .actionSheet(isPresented: $showingExportActionSheet, content: {
            exportActionSheet
        })
        .navigationBarTitle("Viewer", displayMode: .inline)
    }
}
