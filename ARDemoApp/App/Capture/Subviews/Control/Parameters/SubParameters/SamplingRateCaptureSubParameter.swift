//
//  SamplingRateCaptureSubParameter.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 11/05/2021.
//

import SwiftUI
import PointCloudRendererService

struct SamplingRateCaptureSubParameter: View {
    @Binding var verticalSamplingRate: SamplingRate
    @Binding var horizontalSamplingRate: SamplingRate

    var body: some View {
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
                        .foregroundColor(.amazon)
                })

                Spacer()

                Picker(selection: $verticalSamplingRate, label: Text("")) {
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

                Picker(selection: $horizontalSamplingRate, label: Text("")) {
                    ForEach(SamplingRate.allCases, id: \.self) {
                        Text($0.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
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
