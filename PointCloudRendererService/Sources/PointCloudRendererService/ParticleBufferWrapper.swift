//
//  ParticleBufferWrapper.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 30/04/2021.
//

import MetalKit
import SceneKit.SCNGeometry
import Common

public final class ParticleBufferWrapper: ObservableObject {
    // Hold more info, is >= to count
    public let buffer: MetalBuffer<ParticleUniforms>
    @Published public var count: Int
    // The user selected treshold, to filter buffer
    public var confidenceTreshold: ConfidenceTreshold

    public init(buffer: MetalBuffer<ParticleUniforms>, count: Int, confidenceTreshold: ConfidenceTreshold) {
        self.buffer = buffer
        self.count = count
        self.confidenceTreshold = confidenceTreshold
    }

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
        count = particles.count
    }
}

extension SCNGeometrySource.Semantic {

    // Represent the confidence from the ARKit capture
    public static let confidence = SCNGeometrySource.Semantic(rawValue: "confidence")

}
