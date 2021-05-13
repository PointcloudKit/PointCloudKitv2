//
//  ConfidenceCaptureSubParameterView.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 11/05/2021.
//

import SwiftUI
import PointCloudRendererService

struct ConfidenceCaptureSubParameterView: View {
    @Binding var confidenceThreshold: ConfidenceThreshold

    var body: some View {
        VStack {
            Text("Confidence")
                .foregroundColor(.bone)
            Text("When sampling the world, each point is attributed a weighted value depending of luminosity and distance")
                .font(.caption)
                .foregroundColor(.bone)
            HStack {
                Picker(selection: $confidenceThreshold, label: Text("")) {
                    ForEach(ConfidenceThreshold.allCases, id: \.self) {
                        Text($0.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

extension ConfidenceThreshold {
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
