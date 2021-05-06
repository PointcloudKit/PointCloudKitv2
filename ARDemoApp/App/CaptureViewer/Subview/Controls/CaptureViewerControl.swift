//
//  CaptureViewerControl.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 03/05/2021.
//

import SwiftUI
import PointCloudRendererService
import Common

struct CaptureViewerControl: View {
    @AppStorage(ProcessorParameters.storageKey) private var processorParameters = ProcessorParameters()

    @EnvironmentObject var model: CaptureViewerControlModel

    let particleBuffer: ParticleBufferWrapper
    @Binding var object: Object3D

    let confidenceTreshold: ConfidenceTreshold

    @State private var showExportTypeSelection = false
    @State private var showParameters = false
    @State private var showParameterControls = false
    @State private var showProcessorParametersEditor = false

    @State var processing = false
    @State var exportPLY = false
    @State var lastObject: Object3D?
    @State var undoAvailable = false

    func undo() {
        guard let lastObject = lastObject else { return }
        object = lastObject
        self.lastObject = nil
        undoAvailable = false

        redraw()
    }

    private func update(with object: Object3D) {
        lastObject = self.object
        self.object = object
        undoAvailable = true

        redraw()
    }

    private func redraw() {
        object.particles()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { particles in
                particleBuffer.buffer.assign(with: particles)
            })
            .store(in: &model.cancellables)
    }

    // MARK: - UI

    var exportPlyButton: ActionSheet.Button {
        ActionSheet.Button.default(Text("PLY (Polygon File Format)")) { exportPLY = true }
    }

    var exportActionSheet: ActionSheet {
        var exportButtons = [ActionSheet.Button]()

        exportButtons.append(exportPlyButton)
        exportButtons.append(.cancel())

        return ActionSheet(title: Text("Export Type"), message: Text("Supported export formats"), buttons: exportButtons)
    }

    // MARK: - Paramters

    private var processorsEnabled: Bool { !processing && !showProcessorParametersEditor }
    private var reconstructionEnabled: Bool { processorsEnabled && object.hasVertexNormals }

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
                    // MARK: Normal Estimation
                    Button(action: {
                        processing = true
                        model.normalsEstimation(object, parameters: processorParameters.normalsEstimation)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: {_ in processing = false },
                                  receiveValue: { object in
                                    self.update(with: object)
                                  })
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(
                            title: { Text("Normal Estimation").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "line.diagonal.arrow")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .charredBone)
                                    .padding(.trailing, 1)
                            }
                        )
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Surface Reconstruction
                    Button(action: {
                        processing = true
                        model.poissonSurfaceReconstruction(object, parameters: processorParameters.surfaceReconstruction.poisson)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: {_ in processing = false },
                                  receiveValue: { object in
                                    self.update(with: object)
                                  })
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(
                            title: { Text("Surface Reconstruction").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "skew")
                                    .font(.body)
                                    .foregroundColor(reconstructionEnabled ? .amazon : .charredBone)
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
                        processing = true
                        model.voxelDownsampling(object, parameters: processorParameters.voxelDownSampling)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: {_ in processing = false },
                                  receiveValue: { object in
                                    self.update(with: object)
                                  })
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(title: { Text("Voxel DownSampling").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "cube")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .charredBone)
                              })
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Statistical Outlier Removal
                    Button(action: {
                        processing = true
                        model.statisticalOutlierRemoval(object, parameters: processorParameters.outlierRemoval.statistical)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: {_ in processing = false },
                                  receiveValue: { object in
                                    self.update(with: object)
                                  })
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(title: { Text("Statistical O.R.").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "camera.filters")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .charredBone)
                              })
                    })
                    .disabled(!processorsEnabled)

                    // MARK: Radius Outlier Removal
                    Button(action: {
                        processing = true
                        model.radiusOutlierRemoval(object, parameters: processorParameters.outlierRemoval.radius)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: {_ in processing = false },
                                  receiveValue: { object in
                                    self.update(with: object)
                                  })
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(title: { Text("Radius O.R.").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "aqi.medium")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .charredBone)
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
                        undo()
                    }, label: {
                        Label(
                            title: { Text("Undo").foregroundColor(undoAvailable && processorsEnabled ? .bone : .charredBone) },
                            icon: {
                                Image(systemName: "arrow.uturn.backward.square")
                                    .font(.body)
                                    .foregroundColor(undoAvailable && processorsEnabled  ? .amazon : .charredBone)
                            }
                        )
                    })
                    .disabled(!undoAvailable || !processorsEnabled)

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
                    showExportTypeSelection = true
                }
            }, label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(showParameters || processing ? .charredBone : .bone)
            })
            .disabled(showParameters || processing)
        }
    }

    public var body: some View {
        VStack {
            if model.exportService.exporting {
                ProgressView("\(model.exportService.info)", value: model.exportService.exportProgress,
                             total: 1)
                    .padding(20)
                    .cornerRadius(10, corners: [.topLeft, .topRight])
                    .foregroundColor(.bone)
            }

            if processing {
                ProgressView("Processing...")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .cornerRadius(10, corners: [.topLeft, .topRight])
                    .foregroundColor(.bone)
            }

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
        .actionSheet(isPresented: $showExportTypeSelection) { exportActionSheet }
        .fileExporter(isPresented: $exportPLY,
                      document: model.exportService.generatePLYFile(from: object),
                      contentType: .polygon,
                      onCompletion: { _ in })
        .onDisappear {
            model.cancellables.forEach { cancellable in cancellable.cancel() }
        }
    }
}
