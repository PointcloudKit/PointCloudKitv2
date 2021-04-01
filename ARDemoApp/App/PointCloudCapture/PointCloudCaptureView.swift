//
//  PointCloudCaptureView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import PointCloudRendererService

struct PointCloudCaptureView: View {

    @State var hasCapture: Bool = true
    @State var isCapturing: Bool = true
    @State var isShowingParameters: Bool = false
    @State var isShowingAssetViewer: Bool = false

    // PointCloudCaptureRenderingView' View Model
    @ObservedObject private var viewModel = PointCloudCaptureViewModel()

    var metrics: some View {
        Label(
            title: { Text("\(viewModel.currentPointCount)") },
            icon: {
                Image(systemName: "aqi.medium")
                    .font(.body)
                    .foregroundColor(!isCapturing ? .gray : .red)
            }
        )
    }

    var captureView: some View {
        PointCloudCaptureRenderingView(renderingDelegate: viewModel)
            .background(Color.black)
    }

    var controlsSection: some View {
        HStack {

            NavigationLink(destination: CaptureViewer(model: viewModel.assetViewerModel),
                           isActive: $isShowingAssetViewer) {  }

            Button(action: {
                isShowingParameters.toggle()
            }, label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.gray)
            })

            Spacer()

            Toggle(isOn: $isCapturing, label: { Text("") })
                .toggleStyle(CaptureToggleStyle())
                .onChange(of: isCapturing, perform: { value in
                    switch value {
                    case true:
                        viewModel.flushCapture()
                        viewModel.startCapture()
                        hasCapture = true
                    case false:
                        viewModel.pauseCapture()
                    }
                })

            Spacer()

            Button(action: {
                isShowingAssetViewer = true
            }, label: {
                Image(systemName: "scale.3d")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.gray)
            })
            .hiddenConditionally(isHidden: !(!isCapturing && hasCapture))

        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                VStack {
                    // MARK: - Capture View
                    captureView
                    // MARK: - Controls Section
                    controlsSection
                }
            }
            .statusBar(hidden: true)
            .navigationTitle("Capture")
            .navigationBarItems(trailing: metrics)
        }
        .onAppear {
            // First apperance if
            viewModel.startCapture()
        }
        .onDisappear {
            viewModel.pauseCapture()
            isCapturing = false
        }
    }
}
