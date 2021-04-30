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
import PointCloudRendererService

public struct CaptureViewer: View {
    @AppStorage(ProcessorParameters.storageKey) private var processorParameters = ProcessorParameters()

    @StateObject var sceneRenderingService = SceneRenderingService()
    @StateObject var processorService = ProcessorService()
    @StateObject var exportService = ExportService()

    @State var capture: PointCloudCapture
    @State var scene: SCNScene

    @State var lastObject: Object3D?
    @State var object: Object3D
    @State var undoAvailable: Bool = false

    //    func undo() {
    //        processing = true
    //        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
    //            guard let self = self, let lastObject = self.lastObject else { return }
    //            self.capture.buffer.assign(with: lastObject.particles())
    //            DispatchQueue.main.async {
    //                self.object = lastObject
    //                self.lastObject = nil
    //                self.processing = false
    //            }
    //        }
    //    }

//    private(set) var capture: PointCloudCapture

    @State private var showExportActionSheet = false
    @State private var exportSCN = false
    @State private var exportPLY = false
    // Main Parameters view
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false
    @State private var showProcessorParametersEditor: Bool = false

    var exportScnButton: ActionSheet.Button {
        ActionSheet.Button.default(Text("SCN (Apple's SceneKit)")) { exportSCN = true }
    }

    var exportPlyButton: ActionSheet.Button {
        ActionSheet.Button.default(Text("PLY (Polygon File Format)")) { exportPLY = true }
    }

    var exportActionSheet: ActionSheet {
        var exportButtons = [exportScnButton]

        // TODO check if ply is ready to beexported
        if true {
            exportButtons.append(exportPlyButton)
        }
        exportButtons.append(.cancel())

        return ActionSheet(title: Text("Export Type"), message: Text("Supported export formats"), buttons: exportButtons)
    }

    // MARK: - Paramters

    private var processorsEnabled: Bool { !processorService.processing && !showProcessorParametersEditor }
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
                    // MARK: Surface Reconstruction
                    Button(action: {
                        // Add an Object manager or something that keep track of current object, undos, and do these operations. Then replace these by call to that manager for actions. Manager emcompas the service + state
                        processorService.normalsEstimation(for: object, parameters: processorParameters.normalsEstimation)
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
                        processorService.poissonSurfaceReconstruction(for: object, parameters: processorParameters.surfaceReconstruction.poisson)
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
                        processorService.voxelDownsampling(for: object, parameters: processorParameters.voxelDownSampling)
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
                        processorService.statisticalOutlierRemoval(for: object, parameters: processorParameters.outlierRemoval.statistical)
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
                        processorService.radiusOutlierRemoval(for: object, parameters: processorParameters.outlierRemoval.radius)
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

//                    // MARK: Undo
//                    Button(action: {
//                        model.undo()
//                    }, label: {
//                        Label(
//                            title: { Text("Undo").foregroundColor(model.undoAvailable && processorsEnabled ? .bone : .spaceGray) },
//                            icon: {
//                                Image(systemName: "arrow.uturn.backward.square")
//                                    .font(.body)
//                                    .foregroundColor(model.undoAvailable && processorsEnabled  ? .amazon : .spaceGray)
//                            }
//                        )
//                    })
//                    .disabled(!model.undoAvailable || !processorsEnabled)

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
                    .foregroundColor(showParameters || processorService.processing ? .spaceGray : .bone)
            })
            .disabled(showParameters || processorService.processing)
        }
    }

    public var body: some View {
        ZStack {
            SceneView(scene: scene,
                      pointOfView: scene.rootNode.childNode(withName: NodeIdentifier.camera.rawValue, recursively: false),
                      options: [
                        .rendersContinuously,
                        .allowsCameraControl,
                        .autoenablesDefaultLighting,
                        .temporalAntialiasingEnabled
                      ])

            VStack {

                // Metrics
                if !showProcessorParametersEditor {
                    Metrics(currentPointCount: object.vertices.count,
                            currentNormalCount: object.vertexNormals.count,
                            currentFaceCount: object.triangles.count,
                            activity: true)
                }

                Spacer()

                if sceneRenderingService.rendering {
                    ProgressView("Rendering...")
                        .padding(20)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.bone)
                }


                if processorService.processing {
                    ProgressView("Processing...")
                        .padding(20)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.bone)
                }

//                if showingSCNExporter {
//                    ProgressView("Exporting SCN...", value: model.exportProgress, total: 1)
//                        .hiddenConditionally(!model.exporting)
//                        .fileExporter(isPresented: $showingSCNExporter,
//                                      document: model.scnFile(),
//                                      contentType: .sceneKitScene,
                //                                      onCompletion: { _ in })
                //                        .foregroundColor(.bone)
                //                }

                if exportService.exporting {
                    ProgressView("\(exportService.info)", value: exportService.exportProgress, total: 1)
                        .fileExporter(isPresented: $exportPLY,
                                      document: exportService.generatePLYFile(from: object),
                                      contentType: .polygon,
                                      onCompletion: { _ in })
                        .fileExporter(isPresented: $exportSCN,
                                      document: exportService.generateSCNFile(from: sceneRenderingService.sc),
                                      contentType: .sceneKitScene,
                                      onCompletion: { _ in })
                        .foregroundColor(.bone)
                }
            }

            // Parameters
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
        .navigationBarTitle("Viewer", displayMode: .inline)
    }
}
