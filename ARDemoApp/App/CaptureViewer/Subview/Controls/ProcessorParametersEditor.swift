//
//  ProcessorParametersEditor.swift
//  
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import SwiftUI
import SceneKit
import Common

struct ProcessorParametersEditor: View {

    @Binding var parameters: ProcessorParameters

    var surfaceReconstructionSection: some View {
        VStack {
            HStack {
                Label(
                    title: { Text("Poisson Surface Reconstruction").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "skew")
                            .font(.title2)
                            .foregroundColor(.amazon)
                    }
                )
                Spacer()
            }
            .padding(.top, 10)

            Stepper(value: $parameters.surfaceReconstruction.poisson.depth,
                    in: 1...15,
                    step: 1,
                    label: {
                        Text(parameters.surfaceReconstruction.poisson.depthLabel)
                            .font(Font.caption)
                    })
                .padding(.leading, 40)
        }
    }

    var voxelDownSamplingSection: some View {
        VStack {
            HStack {
                Label(
                    title: { Text("Voxel Down Sampling").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "cube")
                            .font(.title2)
                            .foregroundColor(.amazon)
                    }
                )
                Spacer()
            }
            .padding(.top, 10)

            Stepper(value: $parameters.voxelDownSampling.voxelSize,
                    in: 0.01...1.0,
                    step: 0.01,
                    label: {
                        Text(parameters.voxelDownSampling.voxelSizeLabel)
                            .font(Font.caption)
                    })
                .padding(.leading, 40)
        }
    }

    var outlierRemovalSection: some View {
        VStack {
            HStack {
                Label(
                    title: { Text("Statistical Outlier Removal").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "camera.filters")
                            .font(.title2)
                            .foregroundColor(.amazon)
                    }
                )
                Spacer()
            }
            .padding(.top, 10)
            Stepper(value: $parameters.outlierRemoval.statistical.neighbors,
                    in: 1...50,
                    step: 1,
                    label: {
                        Text(parameters.outlierRemoval.statistical.neighborsLabel)
                            .font(Font.caption)
                    })
                .padding(.leading, 40)
            Stepper(value: $parameters.outlierRemoval.statistical.stdRatio,
                    in: 0.1...10.0,
                    step: 0.1,
                    label: {
                        Text(parameters.outlierRemoval.statistical.stdRatioLabel)
                            .font(Font.caption)
                    })
                .padding(.leading, 40)

            Divider().foregroundColor(.bone)

            HStack {
                Label(
                    title: { Text("Radius Outlier Removal").foregroundColor(.bone) },
                    icon: {
                        Image(systemName: "aqi.medium")
                            .font(.title2)
                            .foregroundColor(.amazon)
                    }
                )
                Spacer()
            }
            .padding(.top, 10)
            Stepper(value: $parameters.outlierRemoval.radius.pointsCount,
                    in: 1...50,
                    step: 1,
                    label: {
                        Text(parameters.outlierRemoval.radius.pointCountLabel)
                            .font(Font.caption)
                    })
                .padding(.leading, 40)
            Stepper(value: $parameters.outlierRemoval.radius.radius,
                    in: 0.005...0.1,
                    step: 0.005,
                    label: {
                        Text(parameters.outlierRemoval.radius.radiusLabel)
                            .font(Font.caption)
                    })
                .padding(.leading, 40)
        }
    }

    var generalSection: some View {
        HStack {
            Button(
                action: {
                    parameters.restoreBaseValues()
                },
                label: {
                    Label(
                        title: { Text("Reset default values").foregroundColor(.bone) },
                        icon: {
                            Image(systemName: "arrow.uturn.backward.square")
                                .font(.title3)
                                .foregroundColor(.amazon)
                        }
                    )
                }
            )
        }
    }

    var body: some View {
        VStack {
            surfaceReconstructionSection

            Divider().foregroundColor(.bone)

            voxelDownSamplingSection

            Divider().foregroundColor(.bone)

            outlierRemovalSection

            Divider().foregroundColor(.bone)

            generalSection
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

extension ProcessorParameters.VoxelDownSampling {
    var voxelSizeLabel: String {
        "voxel size: \(Int(voxelSize * 100)) ㎣"
    }
}

extension ProcessorParameters.OutlierRemoval.Statistical {
    var neighborsLabel: String {
        "neighbor\(neighbors > 1 ? "s" : ""): \(neighbors)"
    }
    var stdRatioLabel: String {
        "standard deviation: \(String(format: "%0.2f", stdRatio))"
    }
}

extension ProcessorParameters.OutlierRemoval.Radius {
    var pointCountLabel: String {
        "\(pointsCount) points"
    }
    var radiusLabel: String {
        "sphere radius: \(Int(radius * 100))㎜"
    }
}

extension ProcessorParameters.SurfaceReconstruction.Poisson {
    var depthLabel: String {
        "search tree depth \(depth)"
    }
}
