//
//  PointCloudRendererService+Asset.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import MetalKit
import SceneKit.SCNGeometry

public struct PointCloudCapture {
    public var buffer: MetalBuffer<ParticleUniforms>
    public var count: Int
    
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
}

extension PointCloudRendererService {
    public var capture: PointCloudCapture {
        PointCloudCapture(buffer: particlesBuffer,
                          count: currentPointCount)
    }
}

extension SCNGeometrySource.Semantic {

    // Represent the confidence from the ARKit capture
    public static let confidence = SCNGeometrySource.Semantic(rawValue: "confidence")

}