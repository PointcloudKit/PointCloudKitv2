//
//  CaptureParametersView.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 11/05/2021.
//

import SwiftUI
import PointCloudRendererService

struct CaptureParametersView: View {

    @EnvironmentObject var renderingService: RenderingService

    @State private var showSubParameter: Bool = false
    @State private var showConfidence: Bool = false
    @State private var showSamplingRate: Bool = false

    @State private var flashlightActive: Bool = false

    var parameters: some View {
        HStack(alignment: .center, spacing: 20) {

            Spacer()

            let flashlightDisabled = showSubParameter
            // MARK: - Flashlight
            Button(action: {
                flashlightActive = FlashlightService.toggleFlashlight()
            }, label: {
                Label(title: { }, icon: {
                    Image(systemName: flashlightActive ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.title)
                        .foregroundColor(!flashlightDisabled ? .amazon : .charredBone)
                })
            })
            .disabled(flashlightDisabled)

            Spacer()

            let confidenceDisabled = showSubParameter && !showConfidence
            // MARK: - Confidence
            Button(action: {
                withAnimation {
                    showSubParameter.toggle()
                    showConfidence.toggle()
                }
            }, label: {
                Label(title: { }, icon: {
                    Image(systemName: "circlebadge.2")
                        .font(.title)
                        .foregroundColor(!confidenceDisabled ? .amazon : .charredBone)
                })
            })
            .disabled(confidenceDisabled)

            Spacer()

            let captureRateDisabled = showSubParameter && !showSamplingRate
            // MARK: - CaptureRate
            Button(action: {
                withAnimation {
                    showSubParameter.toggle()
                    showSamplingRate.toggle()
                }
            }, label: {
                Label(title: { }, icon: {
                        Image(systemName: "speedometer")
                            .font(.title)
                            .foregroundColor(!captureRateDisabled ? .amazon : .charredBone)
                    })
            })
            .disabled(captureRateDisabled)

            Spacer()
        }
    }

    var body: some View {
        if showSubParameter {

            Group {
                if showConfidence {
                    ConfidenceCaptureSubParameterView(confidenceThreshold: $renderingService.confidenceThreshold)
                }
                if showSamplingRate {
                    SamplingRateCaptureSubParameterView(verticalSamplingRate: $renderingService.verticalSamplingRate,
                                         horizontalSamplingRate: $renderingService.horizontalSamplingRate)
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
    }
}
