//
//  ProcessorParameters.swift
//  
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import Foundation

public struct ProcessorParameters: Codable {
    public struct VoxelDownSampling: Codable {
        public var voxelSize: Double = 0.02
    }
    public struct OutlierRemoval: Codable {
        public struct Statistical: Codable {
            public var neighbors: Int = 20
            public var stdRatio: Double = 2.0
        }
        public struct Radius: Codable {
            public var pointsCount: Int = 16
            public var radius: Double = 0.05
        }

        public var statistical = Statistical()
        public var radius = Radius()
    }

    public var voxelDownSampling = VoxelDownSampling()
    public var outlierRemoval = OutlierRemoval()

    public init() {}
}
