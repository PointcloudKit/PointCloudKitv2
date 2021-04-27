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
    @StateObject private var processorParameters = ProcessorParameters.fromUserDefaultOrNew

    @EnvironmentObject var model: CaptureViewerModel

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

    public init() {}

    var exportActionSheet: ActionSheet {
        ActionSheet(title: Text("Export Type"), message: Text("Supported export formats"), buttons: [
            .default(Text("SCN (Apple's SceneKit)"), action: {
                scnFile = model.scnFile()
                showingSCNExporter = true
            }),
            .default(Text("PLY (Polygon File Format)"), action: {
                DispatchQueue.global(qos: .userInitiated).async {
                    plyFile = model.plyFile()
                    DispatchQueue.main.async {
                        showingPLYExporter = true
                    }
                }
            }),
            .cancel()
        ])
    }

    // MARK: - Paramters

    private var pointCloudProcessorsEnabled: Bool { !model.pointCloudProcessing && !showProcessorParametersEditor }

    var transformingParameters: some View {
        HStack {
            Label(
                title: { },
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
                title: { },
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
                        model.voxelDownsampling(parameters: processorParameters.voxelDownSampling)
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
                        model.statisticalOutlierRemoval(parameters: processorParameters.outlierRemoval.statistical)
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
                        model.radiusOutlierRemoval(parameters: processorParameters.outlierRemoval.radius)
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
                title: { },
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
                        model.undo()
                    }, label: {
                        Label(
                            title: { Text("Undo").foregroundColor(model.undoAvailable && pointCloudProcessorsEnabled ? .white : .gray) },
                            icon: {
                                Image(systemName: "arrow.uturn.backward.square")
                                    .font(.body)
                                    .foregroundColor(model.undoAvailable && pointCloudProcessorsEnabled  ? .red : .gray)
                            }
                        )
                    })
                    .disabled(!model.undoAvailable || !pointCloudProcessorsEnabled)

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
                    .foregroundColor(showParameters || model.pointCloudProcessing ? .gray : .white)
            })
            .disabled(showParameters || model.pointCloudProcessing)
        }
    }

    public var body: some View {
        ZStack {
            SceneView(scene: model.scene,
                      pointOfView: model.cameraNode,
                      options: [
                        .rendersContinuously,
                        .allowsCameraControl,
                        .autoenablesDefaultLighting,
                        .temporalAntialiasingEnabled
                      ])

            VStack {

                // Metrics
                if !showProcessorParametersEditor {
                MetricsView(currentPointCount: $model.vertexCount)
                }

                Spacer()

                ProgressView("Rendering...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .hiddenConditionally(!model.pointCloudRendering)

                ProgressView("Processing...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .hiddenConditionally(!model.pointCloudProcessing)

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
                            ProcessorParametersEditor()
                                .environmentObject(processorParameters)
                                .environmentObject(ProcessorParametersEditorModel(shown: $showProcessorParametersEditor))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .transition(.moveAndFade)
                        }

                        if !showProcessorParametersEditor {
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
                    }

                    if !showProcessorParametersEditor {
                        // Controls Section at the bottom of the screen
                        controlsSection
                            .padding(.top, 10)
                            .padding(.horizontal, 20)
                    }
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
