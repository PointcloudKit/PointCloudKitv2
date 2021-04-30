//
//  CaptureViewer.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import SceneKit
import Common
import ProcessorService

public struct CaptureViewer: View {
    @StateObject private var processorParameters = ProcessorParameters.fromUserDefaultOrNew

    @EnvironmentObject var model: CaptureViewerModel

    @State private var showingExportActionSheet = false
    @State private var showingSCNExporter = false
    @State private var showingPLYExporter = false
    // Main Parameters view
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false
    @State private var showProcessorParametersEditor: Bool = false

    public init() {}

    var exportScnButton: ActionSheet.Button {
        ActionSheet.Button.default(Text("SCN (Apple's SceneKit)")) { showingSCNExporter = true }
    }

    var exportPlyButton: ActionSheet.Button {
        ActionSheet.Button.default(Text("PLY (Polygon File Format)")) { showingPLYExporter = true }
    }

    var exportActionSheet: ActionSheet {
        var exportButtons = [exportScnButton]

        if model.exportPlyAvailable {
            exportButtons.append(exportPlyButton)
        }
        exportButtons.append(.cancel())

        return ActionSheet(title: Text("Export Type"), message: Text("Supported export formats"), buttons: exportButtons)
    }

    // MARK: - Paramters

    private var processorsEnabled: Bool { !model.processing && !showProcessorParametersEditor }
    private var reconstructionEnabled: Bool { processorsEnabled && model.normalsAvailable }

    var transformingParameters: some View {
        HStack {
            Label(
                title: { },
                icon: {
                    Image(systemName: "wand.and.stars")
                        .font(.body)
                        .foregroundColor(.bone)
                }
            )

            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack {
                    // MARK: Surface Reconstruction
                    Button(action: {
                        model.normalsEstimation(parameters: processorParameters.normalsEstimation)
                    }, label: {
                        Label(
                            title: { Text("Normal Estimation").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "line.diagonal.arrow")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .spaceGray)
                                    .padding(.trailing, 1)
                            }
                        )
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Surface Reconstruction
                    Button(action: {
                        model.poissonSurfaceReconstruction(parameters: processorParameters.surfaceReconstruction.poisson)
                    }, label: {
                        Label(
                            title: { Text("Surface Reconstruction").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "skew")
                                    .font(.body)
                                    .foregroundColor(reconstructionEnabled ? .amazon : .spaceGray)
                            }
                        )
                    })
                    .disabled(!reconstructionEnabled)
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
                        .foregroundColor(.bone)
                }
            )

            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack {
                    // MARK: Voxel DownSampling
                    Button(action: {
                        model.voxelDownsampling(parameters: processorParameters.voxelDownSampling)
                    }, label: {
                        Label(
                            title: { Text("Voxel DownSampling").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "cube")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .spaceGray)
                            }
                        )
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Statistical Outlier Removal
                    Button(action: {
                        model.statisticalOutlierRemoval(parameters: processorParameters.outlierRemoval.statistical)
                    }, label: {
                        Label(
                            title: { Text("Statistical O.R.").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "aqi.high")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .spaceGray)
                            }
                        )
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Radius Outlier Removal
                    Button(action: {
                        model.radiusOutlierRemoval(parameters: processorParameters.outlierRemoval.radius)
                    }, label: {
                        Label(
                            title: { Text("Radius O.R.").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "aqi.medium")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .spaceGray)
                            }
                        )
                    })
                    .disabled(!processorsEnabled)
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
                        .foregroundColor(.bone)
                }
            )

            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack {

                    // MARK: Undo
                    Button(action: {
                        model.undo()
                    }, label: {
                        Label(
                            title: { Text("Undo").foregroundColor(model.undoAvailable && processorsEnabled ? .bone : .spaceGray) },
                            icon: {
                                Image(systemName: "arrow.uturn.backward.square")
                                    .font(.body)
                                    .foregroundColor(model.undoAvailable && processorsEnabled  ? .amazon : .spaceGray)
                            }
                        )
                    })
                    .disabled(!model.undoAvailable || !processorsEnabled)

                    // MARK: Processing Parameters
                    Button(action: {
                        withAnimation {
                            showProcessorParametersEditor.toggle()
                        }
                    }, label: {
                        Label(
                            title: { Text("Processing Config.").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "slider.horizontal.below.square.fill.and.square")
                                    .font(.body)
                                    .foregroundColor(.amazon)
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
                    .foregroundColor(showParameters ? .amazon : .bone)
            })

            Spacer()

            Button(action: {
                withAnimation {
                    showingExportActionSheet = true
                }
            }, label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(showParameters || model.processing ? .spaceGray : .bone)
            })
            .disabled(showParameters || model.processing)
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
                    // TODO use real data
                    Metrics(currentPointCount: .constant(0),
                            currentNormalCount: .constant(0),
                            currentFaceCount: .constant(0),
                            activity: .constant(true))
                }

                Spacer()

                ProgressView("Rendering...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .hiddenConditionally(!model.rendering)
                    .foregroundColor(.bone)

                ProgressView("Processing...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .hiddenConditionally(!model.processing)
                    .foregroundColor(.bone)

                if showingSCNExporter {
                    ProgressView("Exporting SCN...", value: model.exportProgress, total: 1)
                        .hiddenConditionally(!model.exporting)
                        .fileExporter(isPresented: $showingSCNExporter,
                                      document: model.scnFile(),
                                      contentType: .sceneKitScene,
                                      onCompletion: { _ in })
                        .foregroundColor(.bone)
                }
                if showingPLYExporter {
                    ProgressView("Exporting PLY...", value: model.exportProgress, total: 1)
                        .hiddenConditionally(!model.exporting)
                        .fileExporter(isPresented: $showingPLYExporter,
                                      document: model.plyFile(),
                                      contentType: .polygon,
                                      onCompletion: { _ in })
                        .foregroundColor(.bone)
                }

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
                                .padding(.top, 10)
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
