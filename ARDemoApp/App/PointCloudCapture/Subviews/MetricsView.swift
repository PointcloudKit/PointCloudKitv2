//
//  MetricsView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 12/04/2021.
//

import SwiftUI

struct MetricsView: View {

    @Binding var currentPointCount: Int
    @Binding var captureToggled: Bool

    var body: some View {
        HStack {
            Spacer()

            VStack {
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        title: { Text("\(currentPointCount)") },
                        icon: {
                            Image(systemName: "aqi.medium")
                                .font(.body)
                                .foregroundColor(!captureToggled ? .gray : .red)
                        }
                    )
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)

            }
            .background(Color.black.opacity(0.8))
            .cornerRadius(20, corners: [.bottomLeft])
            .clipped()
        }
    }
}
