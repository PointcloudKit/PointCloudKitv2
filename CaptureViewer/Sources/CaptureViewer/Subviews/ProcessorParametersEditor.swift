//
//  ProcessorParametersEditor.swift
//  
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import SwiftUI
import SceneKit
import Common

// MARK: - Processing Parameters

struct ProcessorParametersEditor: View {
    @EnvironmentObject var parameters: ProcessorParameters

    var body: some View {
        VStack {

            // Down Sampling
            HStack {
                Label(
                    title: { Text("Voxel Down Sampling").foregroundColor(.gray) },
                    icon: {
                        Image(systemName: "cube")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                )
                Spacer()
            }
            .padding(.top, 10)
            Group {
                Stepper(value: $parameters.voxelDownSampling.voxelSize,
                        in: 0.01...1.0,
                        step: 0.01,
                        label: {
                            Text(parameters.voxelDownSampling.voxelSizeLabel)
                                .font(Font.caption)
                        })
            }
            .padding(.leading, 40)

            // Outlier Removal
            HStack {
                Label(
                    title: { Text("Statistical Outlier Removal").foregroundColor(.gray) },
                    icon: {
                        Image(systemName: "livephoto")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                )
                Spacer()
            }
            .padding(.top, 10)
            Group {
                Stepper(value: $parameters.outlierRemoval.statistical.neighbors,
                        in: 1...50,
                        step: 1,
                        label: {
                            Text(parameters.outlierRemoval.statistical.neighborsLabel)
                                .font(Font.caption)
                        })
                Stepper(value: $parameters.outlierRemoval.statistical.stdRatio,
                        in: 0.1...10.0,
                        step: 0.1,
                        label: {
                            Text(parameters.outlierRemoval.statistical.stdRatioLabel)
                                .font(Font.caption)
                        })
            }
            .padding(.leading, 40)
            HStack {
                Label(
                    title: { Text("Radius Outlier Removal").foregroundColor(.gray) },
                    icon: {
                        Image(systemName: "livephoto")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                )
                Spacer()
            }
            .padding(.top, 10)
            Group {
                Stepper(value: $parameters.outlierRemoval.radius.pointsCount,
                        in: 1...50,
                        step: 1,
                        label: {
                            Text(parameters.outlierRemoval.radius.pointCountLabel)
                                .font(Font.caption)
                        })
                Stepper(value: $parameters.outlierRemoval.radius.radius,
                        in: 0.005...0.1,
                        step: 0.005,
                        label: {
                            Text(parameters.outlierRemoval.radius.radiusLabel)
                                .font(Font.caption)
                        })
            }
            .padding(.leading, 40)
        }
    }
}

extension ProcessorParameters.VoxelDownSampling {
    var voxelSizeLabel: String {
        "voxel size: \(String(format: "%2f", voxelSize))㎣"
    }
}

extension ProcessorParameters.OutlierRemoval.Statistical {
    var neighborsLabel: String {
        "neighbor\(neighbors > 1 ? "s" : ""): \(neighbors)"
    }
    var stdRatioLabel: String {
        "standard deviation: \(stdRatio)"
    }
}

extension ProcessorParameters.OutlierRemoval.Radius {
    var pointCountLabel: String {
        "points: \(pointsCount)"
    }
    var radiusLabel: String {
        "sphere radius: \(radius)㎜"
    }
}
