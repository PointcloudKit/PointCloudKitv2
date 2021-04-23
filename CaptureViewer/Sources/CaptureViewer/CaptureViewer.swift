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
    @State private var showProcessorParametersEditor: Bool = false
    @State private var processorParameters = ProcessorParameters.fromUserDefaultOrNew

    public init() {}

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

    private var pointCloudProcessorsEnabled: Bool { !viewModel.pointCloudProcessing && !showProcessorParametersEditor }

    var processorParametersEditor: some View {
        ProcessorParametersEditor()
            .environmentObject(processorParameters)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .transition(.slide)
    }

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
                                    .foregroundColor(pointCloudProcessorsEnabled ? .red : .gray)
                            }
                        )
                    })
                    .disabled(!pointCloudProcessorsEnabled)
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
                        viewModel.voxelDownsampling(parameters: processorParameters.voxelDownSampling)
                    }, label: {
                        Label(
                            title: { Text("Voxel DownSampling").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "cube")
                                    .font(.body)
                                    .foregroundColor(pointCloudProcessorsEnabled ? .red : .gray)
                            }
                        )
                    })
                    .disabled(!pointCloudProcessorsEnabled)

                    // MARK: Statistical Outlier Removal
                    Button(action: {
                        viewModel.statisticalOutlierRemoval(parameters: processorParameters.outlierRemoval.statistical)
                    }, label: {
                        Label(
                            title: { Text("Statistical O.R.").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "aqi.high")
                                    .font(.body)
                                    .foregroundColor(pointCloudProcessorsEnabled ? .red : .gray)
                            }
                        )
                    })
                    .disabled(!pointCloudProcessorsEnabled)

                    // MARK: Radius Outlier Removal
                    Button(action: {
                        viewModel.radiusOutlierRemoval(parameters: processorParameters.outlierRemoval.radius)
                    }, label: {
                        Label(
                            title: { Text("Radius O.R.").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "aqi.medium")
                                    .font(.body)
                                    .foregroundColor(pointCloudProcessorsEnabled ? .red : .gray)
                            }
                        )
                    })
                    .disabled(!pointCloudProcessorsEnabled)
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
                            title: { Text("Undo").foregroundColor(viewModel.undoAvailable && pointCloudProcessorsEnabled ? .white : .gray) },
                            icon: {
                                Image(systemName: "arrow.uturn.backward.square")
                                    .font(.body)
                                    .foregroundColor(viewModel.undoAvailable && pointCloudProcessorsEnabled  ? .red : .gray)
                            }
                        )
                    })
                    .disabled(!viewModel.undoAvailable || !pointCloudProcessorsEnabled)

//                    // MARK: Redo
//                    Button(action: {
//                        viewModel.redo()
//                    }, label: {
//                        Label(
//                            title: { Text("Redo").foregroundColor(viewModel.redoAvailable ? .white : .gray) },
//                            icon: {
//                                Image(systemName: "arrow.uturn.forward.square")
//                                    .font(.body)
//                                    .foregroundColor(!viewModel.undoAvailable || !viewModel.pointCloudProcessing ? .red : .gray)
//                            }
//                        )
//                    })
//                    .disabled(!viewModel.undoAvailable || viewModel.pointCloudProcessing)

                    // MARK: Processing Parameters
                    Button(action: {
                        withAnimation {
                            showProcessorParametersEditor.toggle()
                        }
                    }, label: {
                        Label(
                            title: { Text("Processing Config.").foregroundColor(.white) },
                            icon: {
                                Image(systemName: "slider.horizontal.below.square.fill.and.square")
                                    .font(.body)
                                    .foregroundColor(.red)
                            }
                        )
                    })

                    // MARK: Reset Processing Parameters
                    Button(action: {
                        processorParameters = ProcessorParameters()
                        processorParameters.writeToUserDefault()
                    }, label: {
                        Label(
                            title: { Text("Reset").foregroundColor(viewModel.undoAvailable && pointCloudProcessorsEnabled ? .white : .gray) },
                            icon: {
                                Image(systemName: "arrow.uturn.backward.square")
                                    .font(.body)
                                    .foregroundColor(.red)
                            }
                        )
                    })
                    .hiddenConditionally(!showProcessorParametersEditor)
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
                    .hiddenConditionally(!viewModel.pointCloudRendering)

                ProgressView("Processing...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .hiddenConditionally(!viewModel.pointCloudProcessing)

                ProgressView("Exporting SCN...", value: scnFile.writeToDiskProgress, total: 1)
                    .hiddenConditionally(!scnFile.writtingToDisk)
                    .fileExporter(isPresented: $showingSCNExporter,
                                  document: scnFile,
                                  contentType: .sceneKitScene,
                                  onCompletion: { _ in })

                ProgressView("Exporting PLY...", value: plyFile.writeToDiskProgress, total: 1)
                    .hiddenConditionally(!plyFile.writtingToDisk)
                    .fileExporter(isPresented: $showingPLYExporter,
                                  document: plyFile,
                                  contentType: .polygon,
                                  onCompletion: { _ in })

                // Parameters
                VStack {

                    // Toggleable parameters list from the Controls section left bottom button
                    if showParameters {
                        if showProcessorParametersEditor {
                            processorParametersEditor
                                .onDisappear {
                                    processorParameters.writeToUserDefault()
                                }
                        }
                        transformingParameters
                            .padding(.horizontal, 20)
                            .transition(.moveAndFade)
                        cleaningParameters
                            .padding(.horizontal, 20)
                            .transition(.moveAndFade)
                        genericParameters
                            .padding(.horizontal, 20)
                            .transition(.moveAndFade)
                            .onDisappear {
                                showProcessorParametersEditor = false
                            }
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
