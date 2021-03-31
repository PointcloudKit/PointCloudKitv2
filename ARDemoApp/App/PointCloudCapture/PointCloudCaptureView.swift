//
//  PointCloudCaptureView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI
import PointCloudRenderer

struct PointCloudCaptureView: View {

    @State public var hasCapture: Bool = false
    @State public var isCapturing: Bool = false
    @State public var isShowingParameters: Bool = false

    //
    @ObservedObject var pointCloudRenderer = PointCloudRenderer(metalDevice: MTLCreateSystemDefaultDevice()!)

    // PointCloudCaptureRenderingView' View Model
    private var pointCloudCaptureViewModel: PointCloudCaptureRenderingView.ViewModel {
        PointCloudCaptureRenderingView.ViewModel(renderingService: pointCloudRenderer)
    }

    var body: some View {
        ZStack {
            Color.black

            VStack {

                // MARK: - Top Section
                HStack {

                    Spacer()

                    Label(
                        title: { Text("\(pointCloudCaptureViewModel.pointCount)") },
                        icon: {
                            Image(systemName: "aqi.medium")
                                .font(.body)
                                .foregroundColor(!isCapturing ? .gray : .red)
                        }
                    )

                    Spacer()

                }
                .padding(.horizontal, 20)

                // MARK: - Middle Capture View
                PointCloudCaptureRenderingView(viewModel: pointCloudCaptureViewModel)
                    .background(Color.black)
                    .animation(.easeInOut)
                    .onAppear(perform: {
                        pointCloudCaptureViewModel.startCapture()
                        isCapturing = true
                        hasCapture = true
                    })
                    .onDisappear(perform: {
                        pointCloudCaptureViewModel.pauseCapture()
                        isCapturing = false
                    })

                HStack {

                    Button(action: {
                        isShowingParameters.toggle()
                    }, label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 42, weight: .regular))
                            .foregroundColor(.gray)
                    })
                    // Add parameters for displaying a controls overlay

                    Spacer()

                    Toggle(isOn: $isCapturing, label: { Text("") })
                        .toggleStyle(CaptureToggleStyle())
                        .onChange(of: isCapturing, perform: { value in
                            switch value {
                            case true:
                                pointCloudCaptureViewModel.flushCapture()
                                pointCloudCaptureViewModel.startCapture()
                                hasCapture = true
                            case false:
                                pointCloudCaptureViewModel.pauseCapture()
                            }
                        })

                    Spacer()

                    // MARK: - Bottom Controls Section
                    Button(action: {
//                        pointCloudCaptureViewModel.export()
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
        }
        .statusBar(hidden: true)
    }
}
