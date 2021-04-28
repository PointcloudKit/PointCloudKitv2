//
//  MetricsView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 12/04/2021.
//

import SwiftUI

public struct MetricsView: View {
    @Binding public var currentPointCount: Int
    @Binding public var currentNormalCount: Int
    @Binding public var currentFaceCount: Int
    @Binding public var activity: Bool

    public init(
        currentPointCount: Binding<Int>,
        currentNormalCount: Binding<Int> = .constant(0),
        currentFaceCount: Binding<Int> = .constant(0),
        activity: Binding<Bool> = .constant(true)
    ) {
        self._currentPointCount = currentPointCount
        self._currentNormalCount = currentNormalCount
        self._currentFaceCount = currentFaceCount
        self._activity = activity
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    title: { Text("\(currentPointCount)") },
                    icon: {
                        Image(systemName: "aqi.medium")
                            .font(.body)
                            .foregroundColor(!activity ? .gray : .red)
                    }
                )

                Label(
                    title: { Text("\(currentNormalCount)") },
                    icon: {
                        Image(systemName: "line.diagonal.arrow")
                            .font(.body)
                            .foregroundColor(!activity ? .gray : .red)
                    }
                )

                Label(
                    title: { Text("\(currentFaceCount)") },
                    icon: {
                        Image(systemName: "square.2.stack.3d")
                            .font(.body)
                            .foregroundColor(!activity ? .gray : .red)
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
