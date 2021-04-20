/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Type-safe utility for working with MTLBuffers.
*/

import MetalKit
import Accelerate

protocol Resource {
    associatedtype Element
}

/// A wrapper around MTLBuffer which provides type safe access and assignment to the underlying MTLBuffer's contents.

public struct MetalBuffer<Element>: Resource {

    /// The underlying MTLBuffer.
    public let rawBuffer: MTLBuffer

    /// The index that the buffer should be bound to during encoding.
    /// Should correspond with the index that the buffer is expected to be at in Metal shaders.
    fileprivate let index: Int

    /// The number of elements of T the buffer can hold.
    let count: Int
    var stride: Int {
        MemoryLayout<Element>.stride
    }

    /// Initializes the buffer with zeros, the buffer is given an appropriate length based on the provided element count.
    init(device: MTLDevice, count: Int, index: UInt32, label: String? = nil, options: MTLResourceOptions = []) {

        guard let buffer = device.makeBuffer(length: MemoryLayout<Element>.stride * count, options: options) else {
            fatalError("Failed to create MTLBuffer.")
        }
        self.rawBuffer = buffer
        self.rawBuffer.label = label
        self.count = count
        self.index = Int(index)
    }

    /// Initializes the buffer with the contents of the provided array.
    init(device: MTLDevice, array: [Element], index: UInt32, options: MTLResourceOptions = []) {

        guard let buffer = device.makeBuffer(bytes: array, length: MemoryLayout<Element>.stride * array.count, options: .storageModeShared) else {
            fatalError("Failed to create MTLBuffer")
        }
        self.rawBuffer = buffer
        self.count = array.count
        self.index = Int(index)
    }

    /// Return the CPU accessible representation of the Metal Buffer
    public func getMemoryRepresentationCopy(for elementCount: Int? = nil) -> [Element] {
        /* * */ let start = DispatchTime.now()

        let count = elementCount != nil ? elementCount! : self.count

        let unsafeMutableContentAdress = rawBuffer.contents().bindMemory(to: Element.self, capacity: count)
        let memoryAlignment = Int(getpagesize())
        var memory: UnsafeMutableRawPointer?
        let byteCount = count * stride

        posix_memalign(&memory, memoryAlignment, byteCount)
        memset(memory, 0, byteCount)
        memcpy(memory, unsafeMutableContentAdress, byteCount)
        /// Might use faster alternative - optimnization for later
        // cblas_dcopy(Int32(byteCount), memory, 1, unsafeMutableContentAdress, 1)
        let content = UnsafeMutableBufferPointer<Element>(start: unsafeMutableContentAdress, count: count)
        let result = [Element](content)
        free(memory)

        /* * */ let end = DispatchTime.now()
        /* * */ let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        /* * */ print(" <*> Time to run \(#function): \(Double(nanoTime) / 1_000_000) ms")
        return result
    }

    /// Replaces the buffer's memory at the specified element index with the provided value.
    func assign<T>(_ value: T, at index: Int = 0) {
        precondition(index <= count - 1, "Index \(index) is greater than maximum allowable index of \(count - 1) for this buffer.")
        withUnsafePointer(to: value) {
            rawBuffer.contents().advanced(by: index * stride).copyMemory(from: $0, byteCount: stride)
        }
    }

    /// Replaces the buffer's memory with the values in the array.
    public func assign<Element>(with array: [Element]) {
        let byteCount = array.count * stride
        precondition(byteCount == rawBuffer.length, "Mismatch between the byte count of the array's contents and the MTLBuffer length.")
        rawBuffer.contents().copyMemory(from: array, byteCount: byteCount)
    }

    /// Returns a copy of the value at the specified element index in the buffer.
    subscript(index: Int) -> Element {
        get {
            precondition(stride * index <= rawBuffer.length - stride, "This buffer is not large enough to have an element at the index: \(index)")
            return rawBuffer.contents().advanced(by: index * stride).load(as: Element.self)
        }

        set {
            assign(newValue, at: index)
        }
    }

}

// Note: This extension is in this file because access to Buffer<T>.buffer is fileprivate.
// Access to Buffer<T>.buffer was made fileprivate to ensure that only this file can touch the underlying MTLBuffer.
extension MTLRenderCommandEncoder {
    func setVertexBuffer<T>(_ vertexBuffer: MetalBuffer<T>, offset: Int = 0) {
        setVertexBuffer(vertexBuffer.rawBuffer, offset: offset, index: vertexBuffer.index)
    }

    func setFragmentBuffer<T>(_ fragmentBuffer: MetalBuffer<T>, offset: Int = 0) {
        setFragmentBuffer(fragmentBuffer.rawBuffer, offset: offset, index: fragmentBuffer.index)
    }

    func setVertexResource<R: Resource>(_ resource: R) {
        if let buffer = resource as? MetalBuffer<R.Element> {
            setVertexBuffer(buffer)
        }

        if let texture = resource as? Texture {
            setVertexTexture(texture.texture, index: texture.index)
        }
    }

    func setFragmentResource<R: Resource>(_ resource: R) {
        if let buffer = resource as? MetalBuffer<R.Element> {
            setFragmentBuffer(buffer)
        }

        if let texture = resource as? Texture {
            setFragmentTexture(texture.texture, index: texture.index)
        }
    }
}

struct Texture: Resource {
    typealias Element = Any

    let texture: MTLTexture
    let index: Int
}
