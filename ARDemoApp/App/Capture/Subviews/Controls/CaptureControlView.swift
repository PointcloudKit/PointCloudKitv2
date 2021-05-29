//
//  CaptureControlView.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 29/04/2021.
//

import Foundation
import SwiftUI
import Common
import PointCloudRendererService

struct CaptureControlView: View {
    enum AlertType {
        case information
        case error(message: String)
    }

    @AppStorage("Capture.firstAppearance") private var firstAppearance = true

    @EnvironmentObject var model: CaptureControlModel

    // MARK: - Local State
    @State private var navigateToCaptureViewer: Bool = false
    @State private var showAlert: Bool = false
    @State private var alert: AlertType = .information
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false

    // The main controls of the view - Parameters, Trash, Info and NavigateToViewer
    var controls: some View {
        HStack {

            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        showParameters.toggle()
                    }
                }, label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .scaleEffect(showParameters ? 0.9 : 1)
                        .foregroundColor(showParameters ? .amazon : .bone)
                })

                let flushAllowed = model.hasCaptureData
                Button(action: { model.flushCapture() }, label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(flushAllowed ? .red : .charredBone)
                })
                .disabled(!flushAllowed)
            }

            Spacer()

            Toggle(isOn: $model.renderingService.capturing, label: { Text("") })
                .toggleStyle(model.toggleStyle)

            Spacer()

            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        alert = .information
                        showAlert = true
                        model.pauseCapture()
                    }
                }, label: {
                    Image(systemName: "info.circle")
                        .font(.title)
                        .foregroundColor(.bone)
                })

                let navigationToCaptureViewerAllowed =  model.hasCaptureData && !showAlert
                Button(action: {
                    model.pauseCapture()
                    navigateToCaptureViewer = true
                }, label: {
                    Image(systemName: "cube.transparent")
                        .font(.title)
                        .foregroundColor(navigationToCaptureViewerAllowed ? .amazon : .charredBone)
                })
                .disabled(!navigationToCaptureViewerAllowed)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            let captureViewerView = CaptureViewerView().environmentObject(model.captureViewerModel)
            NavigationLink(destination: captureViewerView, isActive: $navigateToCaptureViewer) { }

            if showParameters {
                CaptureParametersView()
                    .environmentObject(model.captureParametersModel)

                Divider()
                    .padding(.bottom, 10)
            }

            controls
        }
        .onAppear {
            if firstAppearance {
                alert = .information
                showAlert = true
                firstAppearance = false
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Capturing Point Cloud"),
                  message: Text("This application allow you to sample the world around you using RGBD data. \nColor and Luminosity come from the Camera feed, meanwhile the new LiDAR sensor allows to capture depth information even in low light environments. \nThis app combine these informations each frame to generate vertices and then process them in the next screen (The Cube button below). \nIn order to get new data, move the phone around!"),
                  dismissButton: .default(Text("Got it!"), action: { }))

        }
    }
}
