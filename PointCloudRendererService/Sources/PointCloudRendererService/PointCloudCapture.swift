//
//  PointCloudCapture.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 30/04/2021.
//

import MetalKit
import SceneKit.SCNGeometry
import Common

public struct PointCloudCapture {
    public var buffer: MetalBuffer<ParticleUniforms>
    public var count: Int
    public var confidenceTreshold: ConfidenceTreshold

    public var stride: Int {
        buffer.stride
    }

    public enum Component {
        case position
        case color
        case confidence

        public var format: MTLVertexFormat {
            switch self {
            case .position:
                return MTKMetalVertexFormatFromModelIO(.float3)
            case .color:
                return MTKMetalVertexFormatFromModelIO(.float3)
            case .confidence:
                return MTKMetalVertexFormatFromModelIO(.float)
            }
        }

        public var dataOffset: Int {
            switch self {
            case .position:
                return 0
            case .color:
                return MemoryLayout<Float3>.stride
            case .confidence:
                return MemoryLayout<Float>.stride
            }
        }

        public var semantic: SCNGeometrySource.Semantic {
            switch self {
            case .position:
                return .vertex
            case .color:
                return .color
            case .confidence:
                return .confidence
            }
        }
    }

    public func reloadBufferContent(with particles: [ParticleUniforms]) {
        buffer.assign(with: particles)
    }
}


extension SCNGeometrySource.Semantic {

    // Represent the confidence from the ARKit capture
    public static let confidence = SCNGeometrySource.Semantic(rawValue: "confidence")

}
