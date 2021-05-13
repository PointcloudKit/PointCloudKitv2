//
//  MetricsView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 12/04/2021.
//

import SwiftUI

final class MetricsModel: ObservableObject {
    @Published var currentPointCount: Int = 0
    @Published var currentNormalCount: Int = 0
    @Published var currentFaceCount: Int = 0
    @Published var activity: Bool = true
}

struct MetricsView: View {

    @EnvironmentObject var model: MetricsModel

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    title: { Text("\(model.currentPointCount)").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "aqi.medium")
                            .font(.body)
                            .foregroundColor(!model.activity ? .charredBone : .amazon)
                    }
                )

                Label(
                    title: { Text(" \(model.currentNormalCount)").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "line.diagonal.arrow")
                            .font(.body)
                            .foregroundColor(!model.activity ? .charredBone : .amazon)
                    }
                )

                Label(
                    title: { Text("\(model.currentFaceCount)").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "square.2.stack.3d")
                            .font(.body)
                            .foregroundColor(!model.activity ? .charredBone : .amazon)
                    }
                )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20, corners: [.allCorners])
            .clipped()

            Spacer()
        }
        .padding(.top, 10)
        .padding(.trailing, 10)
    }
}
