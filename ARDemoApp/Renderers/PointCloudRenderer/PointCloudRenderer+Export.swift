//
//  PointCloudRenderer+Export.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 25/03/2021.
//

import MetalKit
import ModelIO

//import ARKit
//import RealityKit

extension PointCloudRenderer {
    func generateAsset() -> MDLAsset {
        // Using the Model I/O framework to export the scan, so we're initialising an MDLAsset object,
        // which we can export to a file later, with a buffer allocator
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(bufferAllocator: allocator)

        // Initializing MDLMeshBuffers with the content of the particles MTLBuffer
        let byteCountVertices = particlesBuffer.count * particlesBuffer.stride
        let vertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: particlesBuffer.buffer.contents(),
                                                          count: byteCountVertices,
                                                          deallocator: .none),
                                               type: .vertex)

        // Creating a MDLVertexDescriptor to describe the memory layout of the vertex data
        let positionFormat = MTKModelIOVertexFormatFromMetal(.float3)
        let colorFormat = MTKModelIOVertexFormatFromMetal(.float3)
        let confidenceFormat = MTKModelIOVertexFormatFromMetal(.float)
        let vertexDescriptor = MDLVertexDescriptor()
        let sizeOfFloat3 = MemoryLayout.size(ofValue: SIMD3<Float>())

        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: positionFormat,
                                                            offset: 0,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeColor,
                                                            format: colorFormat,
                                                            offset: sizeOfFloat3,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: "MDLVertexAttributeConfidence",
                                                            format: confidenceFormat,
                                                            offset: sizeOfFloat3 * 2,
                                                            bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: particlesBuffer.stride)
        vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: particlesBuffer.stride)
        vertexDescriptor.layouts[2] = MDLVertexBufferLayout(stride: particlesBuffer.stride)

        // Finally creating the MDLMesh and adding it to the MDLAsset
        let mesh = MDLMesh(vertexBuffer: vertexBuffer,
                           vertexCount: particlesBuffer.count,
                           descriptor: vertexDescriptor, submeshes: [])
        asset.add(mesh)

        return asset
    }

    // The actual export code - Need to add that somewhere on a button
    // The above func is a far fetch try to convert the MTL buffer to a MDLMesh>Asset so that it can be exported to Obj/Usdz or rendered costeffectively in a scn scene?
    // But porbably the descriptor part is all wrong and nothing will happen
    // but to test need to create a way to interact with the PointCloudCaptureView. And probably with either need to make it behave like a UIKit view a bit more

//    // Setting the path to export the OBJ file to
//    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//    let urlOBJ = documentsPath.appendingPathComponent("scan.obj")
//
//    // Exporting the OBJ file
//    if MDLAsset.canExportFileExtension("obj") {
//        do {
//            try asset.export(to: urlOBJ)
//
//            // Sharing the OBJ file
//            let activityController = UIActivityViewController(activityItems: [urlOBJ], applicationActivities: nil)
//            activityController.popoverPresentationController?.sourceView = sender
//            self.present(activityController, animated: true, completion: nil)
//        } catch let error {
//            fatalError(error.localizedDescription)
//        }
//    } else {
//        fatalError("Can't export OBJ")
//    }
}
