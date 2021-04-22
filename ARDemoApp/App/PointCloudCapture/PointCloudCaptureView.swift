//
//  PointCloudCaptureView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import Common
import PointCloudRendererService

import CaptureViewer

struct PointCloudCaptureView: View {

    @State private var captureToggled: Bool = true
    // Used for navigation to the Viewer
    @State private var presentCaptureViewer: Bool = false
    // Main Parameters view
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false
    @State private var flashlightActive: Bool = false

    // PointCloudCaptureRenderingView' View Model
    @ObservedObject private var viewModel = PointCloudCaptureViewModel()

    // MARK: - Parameters
    var parameters: some View {
        HStack {
            // MARK: - Flashlight Control
            Button(action: {
                flashlightActive = viewModel.toggleFlashlight()
            }, label: {
                Label(
                    title: { Text("Flashlight").foregroundColor(.white) },
                    icon: {
                        Image(systemName: flashlightActive ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                )
            })

            // MARK: - Confidence Control
            Button(action: {

            }, label: {
                Label(
                    title: { Text("Confidence").foregroundColor(.white) },
                    icon: {
                        Image(systemName: "circlebadge.2")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                )
            })

            Spacer()

            // MARK: - CaptureRate Control
            Button(action: {

            }, label: {
                Label(
                    title: { Text("Capture Rate").foregroundColor(.white) },
                    icon: {
                        Image(systemName: "speedometer")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                )
            })
        }
    }

    // MARK: - Controls of the view
    var controlsSection: some View {
        HStack {
            if presentCaptureViewer {
                NavigationLink(destination: CaptureViewer()
                                .environmentObject(viewModel.captureViewerViewModel()),
                               isActive: $presentCaptureViewer) {  }
            }

            Button(action: {
                withAnimation {
                    showParameters.toggle()
                }
            }, label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 42, weight: .regular))
                    .scaleEffect(showParameters ? 0.9 : 1)
                    .foregroundColor(viewModel.isShowingCoachingOverlay ? .gray : (showParameters ? .red : .white))
            })
            .disabled(viewModel.isShowingCoachingOverlay)

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
                .disabled(viewModel.isShowingCoachingOverlay)

            Spacer()

            Button(action: {
                presentCaptureViewer = true
                viewModel.pauseCapture()
            }, label: {
                Image(systemName: "scale.3d")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(captureToggled ? .gray : .white)
            })
            .disabled(captureToggled)

        }
    }

    // MARK: -
    var captureView: some View {
        ZStack {
            // Rendering View
            PointCloudCaptureRenderingView(renderingDelegate: viewModel)

            VStack {
                // Metrics
                MetricsView(currentPointCount: $viewModel.currentPointCount, activity: $captureToggled)

                Spacer()

                // Parameters
                VStack {

                    // Toggleable parameters list from the Controls section left bottom button
                    if showParameters {
                        ScrollView(.horizontal, showsIndicators: true) {
                            parameters
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                        .transition(.moveAndFade)
                    }

                    // Controls Section at the bottom of the screen
                    controlsSection
                        .padding(.bottom, 20)
                        .padding(.horizontal, 20)
                }
                .background(Color.black.opacity(0.8))
            }
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
            .navigationTitle("Capture")
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
