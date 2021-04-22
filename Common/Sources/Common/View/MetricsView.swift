//
//  MetricsView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 12/04/2021.
//

import SwiftUI

public struct MetricsView: View {
    @Binding public var currentPointCount: Int
    @Binding public var activity: Bool

    public init(currentPointCount: Binding<Int>, activity: Binding<Bool> = .constant(true)) {
        self._currentPointCount = currentPointCount
        self._activity = activity
    }

    public var body: some View {
        HStack {
            Spacer()

            VStack {
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        title: { Text("\(currentPointCount)") },
                        icon: {
                            Image(systemName: "aqi.medium")
                                .font(.body)
                                .foregroundColor(!activity ? .gray : .red)
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
