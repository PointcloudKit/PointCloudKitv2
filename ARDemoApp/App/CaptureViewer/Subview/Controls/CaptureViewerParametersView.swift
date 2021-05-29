//
//  CaptureViewerParametersView.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 12/05/2021.
//

import SwiftUI
import PointCloudRendererService
import Common
import Combine

final class CaptureViewerParametersModel {
    public var cancellables = Set<AnyCancellable>()
    let particleBuffer: ParticleBufferWrapper
    let processorService: ProcessorService

    init(particleBuffer: ParticleBufferWrapper, processorService: ProcessorService) {
        self.particleBuffer = particleBuffer
        self.processorService = processorService
    }

    // MARK: - Point Cloud Processing operations - Parameters are from the `ProcessorParameters` in Model
    func voxelDownsampling(_ object: Object3D, parameters: ProcessorParameters.VoxelDownSampling) -> Future<Object3D, ProcessorServiceError> {
        return processorService.voxelDownsampling(of: object, with: parameters)
    }

    func statisticalOutlierRemoval(_ object: Object3D, parameters: ProcessorParameters.OutlierRemoval.Statistical) -> Future<Object3D, ProcessorServiceError> {
        return processorService.statisticalOutlierRemoval(of: object, with: parameters)
    }

    func radiusOutlierRemoval(_ object: Object3D, parameters: ProcessorParameters.OutlierRemoval.Radius) -> Future<Object3D, ProcessorServiceError> {
        return processorService.radiusOutlierRemoval(of: object, with: parameters)
    }

    func normalsEstimation(_ object: Object3D, parameters: ProcessorParameters.NormalsEstimation) -> Future<Object3D, ProcessorServiceError> {
       return processorService.normalsEstimation(of: object, with: parameters)
    }

    func poissonSurfaceReconstruction(_ object: Object3D, parameters: ProcessorParameters.SurfaceReconstruction.Poisson) -> Future<Object3D, ProcessorServiceError> {
        return processorService.poissonSurfaceReconstruction(of: object, with: parameters)
    }
}

struct CaptureViewerParametersView: View {

    let model: CaptureViewerParametersModel

    @AppStorage(ProcessorParameters.storageKey) private var processorParameters = ProcessorParameters()

    @Binding var object: Object3D
    @Binding var showProcessorParametersEditor: Bool
    @Binding var processing: Bool

    @State var undoAvailable = false
    @State var lastObject: Object3D?
    @State var showError: Bool = false
    @State var error: Error?

    private func redraw() {
        object.particles()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { particles in
                model.particleBuffer.buffer.assign(with: particles)
            })
            .store(in: &model.cancellables)
    }

    private func update(with object: Object3D) {
        lastObject = self.object
        self.object = object
        undoAvailable = true

        redraw()
    }

    func undo() {
        guard let lastObject = lastObject else { return }
        object = lastObject
        self.lastObject = nil
        undoAvailable = false

        redraw()
    }

    private var processorsEnabled: Bool { !processing && !showProcessorParametersEditor }

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
                            .sink(receiveCompletion: processingCompleted, receiveValue: receivedFromProcessing)
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
                            .sink(receiveCompletion: processingCompleted, receiveValue: receivedFromProcessing)
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(
                            title: { Text("Surface Reconstruction").foregroundColor(.bone) },
                            icon: {
                                Image(systemName: "skew")
                                    .font(.body)
                                    .foregroundColor(processorsEnabled ? .amazon : .charredBone)
                            }
                        )
                    })
                    .disabled(!processorsEnabled)
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
                            .sink(receiveCompletion: processingCompleted, receiveValue: receivedFromProcessing)
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
                            .sink(receiveCompletion: processingCompleted, receiveValue: receivedFromProcessing)
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(title: { Text("Statistical O.R.").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "aqi.medium")
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
                            .sink(receiveCompletion: processingCompleted, receiveValue: receivedFromProcessing)
                            .store(in: &model.cancellables)
                    }, label: {
                        Label(title: { Text("Radius O.R.").foregroundColor(.bone) },
                              icon: {
                                Image(systemName: "camera.filters")
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

    var body: some View {
        if showProcessorParametersEditor {
            ProcessorParametersEditorView(parameters: $processorParameters)
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
            .alert(isPresented: $showError) {
               Alert(title: Text("Oops"),
                     message: Text(error?.localizedDescription ?? "Unknown"),
                             dismissButton: .default(Text("Ok")))
            }
    }
}

// MARK: - Completion helper for processing functions
extension CaptureViewerParametersView {
    private func receivedFromProcessing(object: Object3D) {
        update(with: object)
    }

    private func processingCompleted(with result: Subscribers.Completion<ProcessorServiceError>) {
        processing = false
        switch result {
        case let .failure(error):
            self.error = error
            showError = true
        default:
            return
        }
    }
}
