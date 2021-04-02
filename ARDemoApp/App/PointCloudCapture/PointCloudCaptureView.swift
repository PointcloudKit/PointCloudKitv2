//
//  PointCloudCaptureView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import PointCloudRendererService

import CaptureViewer

struct PointCloudCaptureView: View {

    @State private var captureToggled: Bool = true

    @State private var isShowingParameters: Bool = false
    @State private var isPresentingCaptureViewer: Bool = false

    // PointCloudCaptureRenderingView' View Model
    @ObservedObject private var viewModel = PointCloudCaptureViewModel()

    var metrics: some View {
        Label(
            title: { Text("\(viewModel.currentPointCount)") },
            icon: {
                Image(systemName: "aqi.medium")
                    .font(.body)
                    .foregroundColor(!captureToggled ? .gray : .red)
            }
        )
    }

    var captureView: some View {
        PointCloudCaptureRenderingView(renderingDelegate: viewModel)
            .background(Color.black)
    }

    var controlsSection: some View {
        HStack {

            NavigationLink(destination: CaptureViewer(model: viewModel.captureViewerModel),
                           isActive: $isPresentingCaptureViewer) {  }

            Button(action: {
                isShowingParameters.toggle()
            }, label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.gray)
            })

            Spacer()

            Toggle(isOn: $captureToggled, label: { Text("") })
                .toggleStyle(CaptureToggleStyle())
                .onChange(of: captureToggled, perform: { value in
                    switch value {
                    case true:
                        viewModel.startSessionAndCapture()
                    case false:
                        viewModel.pauseCapture()
                    }
                })

            Spacer()

            Button(action: {
                isPresentingCaptureViewer = true
                viewModel.pauseCapture()
            }, label: {
                Image(systemName: "scale.3d")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.gray)
            })
            .hiddenConditionally(isHidden: captureToggled)

        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                VStack {
                    // Capture View
                    captureView
                    // Controls Section
                    controlsSection
                }
            }
            .statusBar(hidden: true)
            .navigationTitle("Capture")
            .navigationBarItems(trailing: metrics)
        }
        .onAppear {
            // First apperance if
            viewModel.startSessionAndCapture()
        }
        .onDisappear {
            viewModel.pauseSession()
        }
    }
}
