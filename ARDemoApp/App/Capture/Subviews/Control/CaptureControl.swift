//
//  CaptureControl.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 29/04/2021.
//

import Foundation
import SwiftUI
import Common
import PointCloudRendererService

struct CaptureControl: View {
    @AppStorage("Capture.firstAppearance") private var firstAppearance = true

    // MARK: - Bindings

    @Binding private(set) var showCoachingOverlay: Bool
    @Binding var navigateToCaptureViewer: Bool

    // MARK: - Environment

    @EnvironmentObject var renderingService: RenderingService

    // MARK: - State

    @State private var showParameters: Bool = false
    @State private var showInformation: Bool = false
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
                        .foregroundColor(showCoachingOverlay ? .charredBone : (showParameters ? .amazon : .bone))
                })
                .disabled(showCoachingOverlay)

                let flushAllowed = !showParameters && renderingService.currentPointCount != 0 && !showCoachingOverlay
                Button(action: {
                    withAnimation {
                        renderingService.flush = true
                    }
                }, label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(flushAllowed ? .red : .charredBone)
                })
                .disabled(!flushAllowed)
            }

            Spacer()

            Toggle(isOn: $renderingService.capturing, label: { Text("") })
                .toggleStyle(CaptureToggleStyle())
                .hiddenConditionally(showCoachingOverlay)

            Spacer()

            HStack(spacing: 20) {
                let showInformationAllowed = !showCoachingOverlay
                Button(action: {
                    withAnimation {
                        showInformation = true
                        renderingService.capturing = false
                    }
                }, label: {
                    Image(systemName: "info.circle")
                        .font(.title)
                        .foregroundColor(showInformationAllowed ? .bone : .charredBone)
                })
                .alert(isPresented: $showInformation) {
                    Alert(title: Text("Capturing Point Cloud"),
                          message: Text("This application allow you to sample the world around you using RGBD data. \nColor and Luminosity come from the Camera feed, meanwhile the new LiDAR sensor allows to capture depth information even in low light environments. \nThis app combine these informations each frame to generate vertices and then process them in the next screen (The Cube button below). \nIn order to get new data, move the phone around!"),
                          dismissButton: .default(Text("Got it!"), action: { renderingService.capturing = true }))
                }
                .disabled(!showInformationAllowed)

                let navigationToCaptureViewerAllowed = renderingService.currentPointCount != 0
                    && !showCoachingOverlay
                    && !showInformation
                Button(action: {
                    withAnimation {
                        renderingService.capturing = false
                        navigateToCaptureViewer = true
                    }
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
            if showParameters {
                CaptureParameters()

                Divider()
                    .padding(.bottom, 10)
            }

            controls
        }
        .onAppear {
            if firstAppearance {
                showInformation = true
                firstAppearance = false
            }
        }
    }
}
