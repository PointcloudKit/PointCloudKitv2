//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 30/03/2021.
//

import ARKit
import Common

// Manual type bridging with the ones defined in ShadersType.h - Cannot have bridging headers in Swift Package

// Metal Buffer indices
enum Index {
    public enum Texture: Int {
        case yComponent
        case cbcr
        case depth
        case confidence
    }

    public enum Buffer: UInt32 {
        case pointCloudUniforms
        case particleUniforms
        case gridPoints
    }
}

public struct RGBUniforms {
    public var viewToCamera: Float3x3 = .init()
    public var viewRatio: Float = 0.0
    public var radius: Float = 0.0
}

public struct PointCloudUniforms {
    public var viewProjectionMatrix: Float4x4 = .init()
    public var localToWorld: Float4x4 = .init()
    public var cameraIntrinsicsInversed: Float3x3 = .init()
    public var cameraResolution: Float2 = .init()

    public var particleSize: Float = 0.0
    public var maxPoints: Int32 = 0
    public var pointCloudCurrentIndex: Int32 = 0
    public var confidenceThreshold: Int32 = 0
}

// ParticleUniform defined in Common
