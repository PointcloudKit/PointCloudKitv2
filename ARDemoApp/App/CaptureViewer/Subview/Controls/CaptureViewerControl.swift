//
//  CaptureViewerControl.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 03/05/2021.
//

import SwiftUI

struct CaptureViewerControl: View {
    @AppStorage(ProcessorParameters.storageKey) private var processorParameters = ProcessorParameters()

    @EnvironmentObject var model: CaptureViewerControlModel

    @State private var showExportActionSheet = false
    @State private var exportSCN = false
    @State private var exportPLY = false
    // Main Parameters view
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false
    @State private var showProcessorParametersEditor: Bool = false

    // MARK: - UI

    var exportPlyButton: ActionSheet.Button {
        ActionSheet.Button.default(Text("PLY (Polygon File Format)")) { exportPLY = true }
    }

    var exportActionSheet: ActionSheet {
        var exportButtons = [ActionSheet.Button]()

        // TODO check if PLY is ready to be exported
        if true {
            exportButtons.append(exportPlyButton)
        }
        exportButtons.append(.cancel())

        return ActionSheet(title: Text("Export Type"), message: Text("Supported export formats"), buttons: exportButtons)
    }

    // MARK: - Paramters

    private var processorsEnabled: Bool { !model.processing && !showProcessorParametersEditor }
    private var reconstructionEnabled: Bool { processorsEnabled && model.object.hasVertexNormals }

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
                        Label(title: { Text("Voxel DownSampling").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "cube")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .spaceGray)
                              })
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Statistical Outlier Removal
                    Button(action: {
                        model.statisticalOutlierRemoval(parameters: processorParameters.outlierRemoval.statistical)
                    }, label: {
                        Label(title: { Text("Statistical O.R.").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "aqi.high")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .spaceGray)
                              })
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Radius Outlier Removal
                    Button(action: {
                        model.radiusOutlierRemoval(parameters: processorParameters.outlierRemoval.radius)
                    }, label: {
                        Label(title: { Text("Radius O.R.").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "aqi.medium")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .spaceGray)
                              })
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
                    showExportActionSheet = true
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

            if model.processing {
                ProgressView("Processing...")
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.bone)
            }

            if model.exporting {
                ProgressView("\(model.exportService.info)", value: model.exportService.exportProgress, total: 1)
                    .fileExporter(isPresented: $exportPLY,
                                  document: model.exportService.generatePLYFile(from: model.object),
                                  contentType: .polygon,
                                  onCompletion: { _ in })
                    .foregroundColor(.bone)
            }

            VStack {

                // Toggleable parameters list from the Controls section left bottom button
                if showParameters {
                    if showProcessorParametersEditor {
                        ProcessorParametersEditor(parameters: $processorParameters)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .transition(.moveAndFade)
                    }

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

                if !showProcessorParametersEditor {
                    // Controls Section at the bottom of the screen
                    controlsSection
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }
            }
            .background(Color.black.opacity(0.8))
        }
        .actionSheet(isPresented: $showExportActionSheet, content: {
            exportActionSheet
        })
        .onAppear {
            model.initialize()
        }
    }

}
