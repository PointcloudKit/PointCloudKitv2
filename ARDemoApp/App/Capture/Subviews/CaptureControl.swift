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

    // MARK: - Bindings

    @Binding private(set) var showCoachingOverlay: Bool
    @Binding var navigateToCaptureViewer: Bool

    // MARK: - Environment

    @EnvironmentObject var renderingService: RenderingService

    // MARK: - State

    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false
    @State private var flashlightActive: Bool = false
    @State private var showSubParameter: Bool = false
    @State private var showConfidenceControl: Bool = false
    @State private var showSamplingRateControl: Bool = false

    var samplingRateControl: some View {
        VStack {
            Text("Sampling Rate")
                .foregroundColor(.bone)
            Text("The rate which new data is sampled. Sensors analyse the surrounding world @120 fps, and sample this data to create new points when either the device rotate 2 degrees or translate 2 cm. This rate affect these two sampling triggers.")
                .font(.caption)
                .foregroundColor(.bone)

            HStack {
                Label(title: { }, icon: {
                    Image(systemName: "arrow.up.and.down.square")
                        .font(.title)
                        .foregroundColor(.amazon )
                })

                Spacer()

                Picker(selection: $renderingService.verticalSamplingRate, label: Text("")) {
                    ForEach(SamplingRate.allCases, id: \.self) {
                        Text($0.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            HStack {
                Label(title: { }, icon: {
                    Image(systemName: "arrow.left.and.right.square")
                        .font(.title)
                        .foregroundColor(.amazon)
                })

                Spacer()

                Picker(selection: $renderingService.horizontalSamplingRate, label: Text("")) {
                    ForEach(SamplingRate.allCases, id: \.self) {
                        Text($0.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }

    var confidenceControl: some View {
        VStack {
            Text("Confidence")
                .foregroundColor(.bone)
            Text("When sampling the world, each point is attributed a weighted value depending of luminosity and distance")
                .font(.caption)
                .foregroundColor(.bone)
            HStack {
                Picker(selection: $renderingService.confidenceThreshold, label: Text("")) {
                    ForEach(ConfidenceTreshold.allCases, id: \.self) {
                        Text($0.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }

    // MARK: - Parameters
    var parameters: some View {
        HStack(alignment: .center, spacing: 20) {

            Spacer()

            let flashlightControlDisabled = showSubParameter
            // MARK: - Flashlight Control
            Button(action: {
                flashlightActive = FlashlightService.toggleFlashlight()
            }, label: {
                Label(title: { }, icon: {
                    Image(systemName: flashlightActive ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.title)
                        .foregroundColor(!flashlightControlDisabled ? .amazon : .charredBone)
                })
            })
            .disabled(flashlightControlDisabled)

            Spacer()

            let confidenceControlDisabled = showSubParameter && !showConfidenceControl
            // MARK: - Confidence Control
            Button(action: {
                withAnimation {
                    showSubParameter.toggle()
                    showConfidenceControl.toggle()
                }
            }, label: {
                Label(title: { }, icon: {
                    Image(systemName: "circlebadge.2")
                        .font(.title)
                        .foregroundColor(!confidenceControlDisabled ? .amazon : .charredBone)
                })
            })
            .disabled(confidenceControlDisabled)

            Spacer()

            let captureRateControlDisabled = showSubParameter && !showSamplingRateControl
            // MARK: - CaptureRate Control
            Button(action: {
                withAnimation {
                    showSubParameter.toggle()
                    showSamplingRateControl.toggle()
                }
            }, label: {
                Label(title: { }, icon: {
                        Image(systemName: "speedometer")
                            .font(.title)
                            .foregroundColor(!captureRateControlDisabled ? .amazon : .charredBone)
                    })
            })
            .disabled(captureRateControlDisabled)

            Spacer()
        }
    }

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

            let navigationToCaptureViewerAllowed = !renderingService.capturing
                && renderingService.currentPointCount != 0
                && !showCoachingOverlay
            Button(action: {
                withAnimation {
                    navigateToCaptureViewer = true
                    renderingService.capturing = false
                }
            }, label: {
                Image(systemName: "cube.transparent")
                    .font(.title)
                    .foregroundColor(navigationToCaptureViewerAllowed ? .amazon : .charredBone)
            })
            .disabled(!navigationToCaptureViewerAllowed)
        }
    }

    var body: some View {
        // Parameters
        VStack(spacing: 0) {
            // Toggleable parameters list from the Controls section left bottom button
            if showParameters {
                if showSubParameter {
                    Group {
                        if showConfidenceControl {
                            confidenceControl
                        }
                        if showSamplingRateControl {
                            samplingRateControl
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .transition(.moveAndFade)

                    Divider()
                }

                ScrollView(.horizontal, showsIndicators: true) {
                    parameters
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .transition(.moveAndFade)

                Divider()
            }

            // Show sub controls + toogle capture + go to capture viewer
            controls
        }
    }
}

extension ConfidenceTreshold {
    fileprivate var description: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}

extension SamplingRate {
    fileprivate var description: String {
        switch self {
        case .slow:
            return "slow"
        case .regular:
            return "regular"
        case .fast:
            return "fast"
        }
    }
}
