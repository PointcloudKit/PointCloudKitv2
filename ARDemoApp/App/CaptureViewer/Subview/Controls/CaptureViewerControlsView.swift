//
//  CaptureViewerControlsView.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 03/05/2021.
//

import SwiftUI
import PointCloudRendererService
import Common
import Combine

struct CaptureViewerControlsView: View {
    @AppStorage("CaptureViewerControlsView.firstAppearance") private(set) var firstAppearance = true

    @EnvironmentObject var model: CaptureViewerControlsModel

    @Binding var object: Object3D

    @State private var showExportTypeSelection = false
    @State private var showAlert = false
    @State private var showParameters = false
    @State private var showParameterControls = false
    @State private var showProcessorParametersEditor = false

    @State var processing = false
    @State var exportPLY = false

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

    // MARK: - Controls of the view
    var controlsSection: some View {
        HStack {

            HStack(spacing: 20) {
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

                Button(action: {
                    withAnimation {
                        showAlert = true
                    }
                }, label: {
                    Image(systemName: "info.circle")
                        .font(.title)
                        .foregroundColor(.bone)
                })
            }

            Spacer()

            Button(action: {
                    withAnimation {
                        showExportTypeSelection = true
                    }
                }, label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 42, weight: .regular))
                        .foregroundColor(showParameters || processing ? .charredBone : .bone)
                })
                .disabled(showParameters || processing)

                // Add a share button

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
                CaptureViewerParametersView(model: model.captureViewerParametersModel,
                                            object: $object,
                                            showProcessorParametersEditor: $showProcessorParametersEditor,
                                            processing: $processing)
            }

            if !showProcessorParametersEditor {
                // Controls Section at the bottom of the screen
                controlsSection
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }
        }
        .actionSheet(isPresented: $showExportTypeSelection) { exportActionSheet }
        .fileExporter(isPresented: $exportPLY,
                      document: model.exportService.generatePLYFile(from: object),
                      contentType: .polygon,
                      onCompletion: { _ in })
        .onAppear {
            if firstAppearance {
                showAlert = true
                firstAppearance = false
            }
        }
        .onDisappear {
            model.cancellables.forEach { cancellable in cancellable.cancel() }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Processing and export"),
                  message: Text("The Viewer allows you to navigate in your capture and further denoise/enhance it using on device processing! \nNo more uploading your surroundings to the cloud and waiting hours for processing, this app respect your privacy and cannot be compromised.\n Once satisfied, the right bottom export allow you to save your capture on your phone and share it to the world."),
                  dismissButton: .default(Text("Got it!")))
        }
    }
}
