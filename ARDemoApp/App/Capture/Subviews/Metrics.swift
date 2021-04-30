//
//  MetricsView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 12/04/2021.
//

import SwiftUI

struct Metrics: View {

    // MARK: - Bindings

    private(set) var currentPointCount: Int
    private(set) var currentNormalCount: Int
    private(set) var currentFaceCount: Int
    private(set) var activity: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    title: { Text("\(currentPointCount)").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "aqi.medium")
                            .font(.body)
                            .foregroundColor(!activity ? .spaceGray : .amazon)
                    }
                )

                Label(
                    title: { Text(" \(currentNormalCount)").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "line.diagonal.arrow")
                            .font(.body)
                            .foregroundColor(!activity ? .spaceGray : .amazon)
                    }
                )

                Label(
                    title: { Text("\(currentFaceCount)").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "square.2.stack.3d")
                            .font(.body)
                            .foregroundColor(!activity ? .spaceGray : .amazon)
                    }
                )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20, corners: [.bottomRight])
            .clipped()

            Spacer()
        }
    }
}
