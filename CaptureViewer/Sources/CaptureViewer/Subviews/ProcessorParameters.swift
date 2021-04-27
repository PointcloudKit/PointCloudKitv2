//
//  ProcessorParameters.swift
//  
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import Foundation

public class ProcessorParameters: Codable, ObservableObject {
    @Published public var voxelDownSampling = VoxelDownSampling()
    @Published public var outlierRemoval = OutlierRemoval()

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        voxelDownSampling = try container.decode(VoxelDownSampling.self, forKey: .voxelDownSampling)
        outlierRemoval = try container.decode(OutlierRemoval.self, forKey: .outlierRemoval)
    }

    public func restoreBaseValues() {
        self.voxelDownSampling = VoxelDownSampling()
        self.outlierRemoval = OutlierRemoval()
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

// MARK: - Custom Codable conformance due to @published
extension ProcessorParameters {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(voxelDownSampling, forKey: .voxelDownSampling)
        try container.encode(outlierRemoval, forKey: .outlierRemoval)
    }

    enum CodingKeys: CodingKey {
        case voxelDownSampling
        case outlierRemoval
    }
}
