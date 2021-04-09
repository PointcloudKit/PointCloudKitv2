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
        HStack {
            Spacer()
            Label(
                title: { Text("\(viewModel.currentPointCount)") },
                icon: {
                    Image(systemName: "aqi.medium")
                        .font(.body)
                        .foregroundColor(!captureToggled ? .gray : .red)
                }
            )
        }
    }

    var captureView: some View {
        ZStack {
            PointCloudCaptureRenderingView(renderingDelegate: viewModel)

            VStack {

                Spacer()

                metrics
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.8))

                // Controls Section
                controlsSection
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.8))
            }
        }
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
                    .foregroundColor(.white)
            })
            .disabledConditionally(disabled: viewModel.isShowingCoachingOverlay)

            Spacer()

            Toggle(isOn: $captureToggled, label: { Text("") })
                .toggleStyle(CaptureToggleStyle())
                .onChange(of: captureToggled, perform: { value in
                    switch value {
                    case true:
                        viewModel.startSession()
                        viewModel.resumeCapture()
                    case false:
                        viewModel.pauseCapture()
                    }
                })
                .disabledConditionally(disabled: viewModel.isShowingCoachingOverlay)

            Spacer()

            Button(action: {
                isPresentingCaptureViewer = true
                viewModel.pauseCapture()
            }, label: {
                Image(systemName: "scale.3d")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.white)
            })
            .hiddenConditionally(isHidden: captureToggled && !viewModel.isShowingCoachingOverlay)

        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                captureView
            }
            .statusBar(hidden: true)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Capture")
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.pauseSession()
        }
    }
}
