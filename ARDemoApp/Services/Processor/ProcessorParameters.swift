//
//  ProcessorParameters.swift
//  
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import Foundation

public struct ProcessorParameters: Codable {
    public var voxelDownSampling = VoxelDownSampling()
    public var outlierRemoval = OutlierRemoval()
    public var normalsEstimation = NormalsEstimation()
    public var surfaceReconstruction = SurfaceReconstruction()

    public init() {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        voxelDownSampling = try container.decode(VoxelDownSampling.self, forKey: .voxelDownSampling)
        outlierRemoval = try container.decode(OutlierRemoval.self, forKey: .outlierRemoval)
        normalsEstimation = try container.decode(NormalsEstimation.self, forKey: .normalsEstimation)
        surfaceReconstruction = try container.decode(SurfaceReconstruction.self, forKey: .surfaceReconstruction)
    }

    public mutating func restoreBaseValues() {
        voxelDownSampling = VoxelDownSampling()
        outlierRemoval = OutlierRemoval()
        normalsEstimation = NormalsEstimation()
        surfaceReconstruction = SurfaceReconstruction()
    }
}

extension ProcessorParameters {
    public struct VoxelDownSampling: Codable {
        public var voxelSize: Double = 0.02
    }
    public struct OutlierRemoval: Codable {
        public var statistical = Statistical()
        public var radius = Radius()
    }
    public struct NormalsEstimation: Codable {
        public var radius: Double = 0.1
        public var maxNearestNeighbors: Int = 30
    }
    public struct SurfaceReconstruction: Codable {
        public var poisson = Poisson()
    }
}

extension ProcessorParameters.OutlierRemoval {
    public struct Statistical: Codable {
        public var neighbors: Int = 20
        public var stdRatio: Double = 2.0
    }
    public struct Radius: Codable {
        public var pointsCount: Int = 16
        public var radius: Double = 0.05
    }
}

extension ProcessorParameters.SurfaceReconstruction {
    public struct Poisson: Codable {
        public var depth: Int = 8
    }
}

// MARK: - Custom Codable
extension ProcessorParameters {
    enum CodingKeys: CodingKey {
        case voxelDownSampling
        case outlierRemoval
        case normalsEstimation
        case surfaceReconstruction
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(voxelDownSampling, forKey: .voxelDownSampling)
        try container.encode(outlierRemoval, forKey: .outlierRemoval)
        try container.encode(normalsEstimation, forKey: .normalsEstimation)
        try container.encode(surfaceReconstruction, forKey: .surfaceReconstruction)
    }
}
