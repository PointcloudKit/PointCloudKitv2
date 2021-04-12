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
    // Used for navigation to the Viewer
    @State private var presentCaptureViewer: Bool = false
    // Main Parameters view
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false

    // PointCloudCaptureRenderingView' View Model
    @ObservedObject private var viewModel = PointCloudCaptureViewModel()

    // MARK: - Parameters
    var parameters: some View {
        HStack {
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
            NavigationLink(destination: CaptureViewer(model: viewModel.captureViewerModel),
                           isActive: $presentCaptureViewer) {  }

            Button(action: {
                withAnimation {
                    showParameters.toggle()
                }
            }, label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 42, weight: .regular))
                    .scaleEffect(showParameters ? 0.9 : 1)
                    .foregroundColor(showParameters ? .red : .white)
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
                presentCaptureViewer = true
                viewModel.pauseCapture()
            }, label: {
                Image(systemName: "scale.3d")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.white)
            })
            .hiddenConditionally(isHidden: captureToggled && !viewModel.isShowingCoachingOverlay)

        }
    }

    // MARK: - The core of this view
    var captureView: some View {
        ZStack {
            // Rendering View
            PointCloudCaptureRenderingView(renderingDelegate: viewModel)

            VStack {
                // Metrics
                MetricsView(currentPointCount: $viewModel.currentPointCount, captureToggled: $captureToggled)

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

extension AnyTransition {
    static fileprivate var moveAndFade: AnyTransition {
        AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
    }
}
