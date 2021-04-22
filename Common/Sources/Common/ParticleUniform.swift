//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 22/04/2021.
//

import ARKit

public typealias Float2 = SIMD2<Float>
public typealias Float3 = SIMD3<Float>

public typealias Float3x3 = matrix_float3x3
public typealias Float4x4 = matrix_float4x4

public extension Float {
    static let degreesToRadian = Float.pi / 180
}

public extension Float3x3 {
    mutating func copy(from affine: CGAffineTransform) {
        columns.0 = Float3(Float(affine.a), Float(affine.c), Float(affine.tx))
        columns.1 = Float3(Float(affine.b), Float(affine.d), Float(affine.ty))
        columns.2 = Float3(0, 0, 1)
    }
}

public struct ParticleUniforms {
    public var position: Float3 = .init()
    public var color: Float3 = .init()
    public var confidence: Float = 0.0

    public init() {}
    public init(color: Float3) {
        self.color = color
    }
    public init(position: Float3, color: Float3, confidence: Float = 0.0) {
        self.position = position
        self.color = color
        self.confidence = confidence
    }
}
