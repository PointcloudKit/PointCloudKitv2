//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import Metal
import MetalKit
import ARKit

public protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}
