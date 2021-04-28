//
//  PolygonFileFormat.swift
//  Metra
//
//  Created by Alexandre Camilleri on 16/12/2020.
//

import Foundation
import UniformTypeIdentifiers

/// Represents the .PLY format - http://paulbourke.net/dataformats/ply/
public struct PolygonFileFormat {

    public struct HeaderLine {
        let key: String
        let value: String?

        static let start = HeaderLine(key: Keyword.start)
        static let end = HeaderLine(key: Keyword.end)

        private init(key: Keyword, value: String? = nil) {
            self.key = key.rawValue
            self.value = value
        }

        init(format: Format, version: String) {
            key = Keyword.format.rawValue
            value = "\(format) \(version)"
        }

        init(comment: String) {
            key = Keyword.comment.rawValue
            value = "\(comment)"
        }

        init(element: Element, count: Int) {
            key = "\(Keyword.element)"
            value = "\(element) \(count)"
        }

        init(property: Property, type: PropertyType) {
            key = "\(Keyword.property)"
            value = "\(type) \(property.rawValue)"
        }

        /// Property list initializer
        /// ```
        ///     element face 10
        ///     property list uchar int vertex_index
        /// ```
        init(property: Property, types: [PropertyType]) {
            key = "\(Keyword.property) \(Keyword.list)"
            value = "\(types.map(\.rawValue).joined(separator: " ")) \(property.rawValue)"
        }

    }

    enum Keyword: String {
        case start = "ply", end = "end_header"
        case format, comment, element, property
        case list
    }

    enum Element: String {
        case vertex
        case face
    }

    enum Format: String {
        case ascii
        //        case bin
    }

    enum Property: String {
        case positionX = "x", positionY = "y", positionZ = "z"
        case redComponent = "red", greenComponent = "green", blueComponent = "blue"
        case normalX = "nx", normalY = "ny", normalZ = "nz"
        case confidence
        case vertexIndex = "vertex_index"
    }

    enum PropertyType: String {
        case float, uchar, int
    }

    /// Generates a `Data` instance representing a PolygonFileFormat.
    /// - Returns: The `Data` representation of the PolygonFileFormat instance.
    ///
    /// Example file (remove {comments} from final file):
    ///
    /// ply
    /// format ascii 1.0           { ascii/binary, format version number }
    /// comment made by Greg Turk  { comments keyword specified, like all lines }
    /// comment this file is a cube
    /// element vertex 8           { define "vertex" element, 8 of them in file }
    /// property float x           { vertex contains float "x" coordinate }
    /// property float y           { y coordinate is also a vertex property }
    /// property float z           { z coordinate, too }
    /// element face 6             { there are 6 "face" elements in the file }
    /// property list uchar int vertex_index { "vertex_indices" is a list of ints }
    /// end_header                 { delimits the end of the header }
    /// 0 0 0                      { start of vertex list }
    /// 0 0 1
    /// 0 1 1
    /// 0 1 0
    /// 1 0 0
    /// 1 0 1
    /// 1 1 1
    /// 1 1 0
    /// 4 0 1 2 3                  { start of face list }
    /// 4 7 6 5 4
    /// 4 0 4 5 1
    /// 4 1 5 6 2
    /// 4 2 6 7 3
    /// 4 3 7 4 0
    ///
    public static func generateAsciiData(using object: Object3D, comments: [String]? = nil) -> Data? {
        var header = [HeaderLine]()

        header.append(.start)
        header.append(.init(format: .ascii, version: "1.0"))
        // Add comments
        comments?.forEach({ (comment) in
            header.append(.init(comment: comment))
        })
        // Define Vertice property, if contains any
        if object.hasVertices {
            header.append(.init(element: .vertex, count: object.vertices.count))
            header.append(.init(property: .positionX, type: .float))
            header.append(.init(property: .positionY, type: .float))
            header.append(.init(property: .positionZ, type: .float))
        }
        if object.hasVertexColors {
            header.append(.init(property: .redComponent, type: .uchar))
            header.append(.init(property: .greenComponent, type: .uchar))
            header.append(.init(property: .blueComponent, type: .uchar))
        }
        if object.hasVertexNormals {
            header.append(.init(property: .normalX, type: .float))
            header.append(.init(property: .normalY, type: .float))
            header.append(.init(property: .normalZ, type: .float))
        }
        if object.hasVertexConfidence {
            header.append(.init(property: .confidence, type: .uchar))
        }

        // Define faces property, if any provided
        if object.hasTriangles {
            header.append(.init(element: .face, count: object.triangles.count))
            header.append(.init(property: .vertexIndex, types: [.uchar, .int]))
        }

        header.append(.end)

        var lines = [AsciiRepresentable]()

        lines.append(contentsOf: header)
        lines.append(object)

        let asciiData = lines
            .joinedAsciiRepresentation()
            .data(using: .ascii)

        return asciiData
    }
}

private protocol AsciiRepresentable {
    var ascii: String { get }
}
//
//extension ParticleUniforms: AsciiRepresentable {
//    #warning("Improve these conversion - just hacking now")
//    fileprivate var ascii: String { "\(position.x) \(position.y) \(position.z) \(UInt(color.x * 255)) \(UInt(color.y * 255)) \(UInt(color.z * 255)) \(UInt(confidence))" }
//}
//
//extension FaceUniforms: AsciiRepresentable {
//    fileprivate var ascii: String { "\(vertexIndices.count) \(vertexIndices.map { String($0) }.joined(separator: " ") )" }
//}

extension Object3D: AsciiRepresentable {
    fileprivate func position(for index: Int) -> String {
        assert(hasVertices)
        let vertex = vertices[index]
        return "\(vertex.x) \(vertex.y) \(vertex.z)"
    }
    fileprivate func color(for index: Int) -> String {
        assert(hasVertexColors)
        let color = vertexColors[index]
        return "\(color.x.rgb) \(color.y.rgb) \(color.z.rgb)"
    }
    fileprivate func normal(for index: Int) -> String {
        assert(hasVertexNormals)
        let normal = vertexNormals[index]
        return "\(normal.x) \(normal.y) \(normal.z)"
    }
    fileprivate func confidence(for index: Int) -> String {
        assert(hasVertexConfidence)
        let confidence = vertexConfidence[index]
        return "\(confidence)"
    }
    fileprivate func triangle(for index: Int) -> String {
        assert(hasTriangles)
        let triangle = triangles[index]
        return "3 \(triangle.x) \(triangle.y) \(triangle.z)"
    }
    fileprivate var ascii: String {
        // MARK: Vertices
        var verticesProcessors = [((Int) -> String)]()

        // Check once
        if hasVertices {
            verticesProcessors.append(position(for:))
            if hasVertexColors { verticesProcessors.append(color(for:)) }
            if hasVertexNormals { verticesProcessors.append(normal(for:)) }
            if hasVertexConfidence { verticesProcessors.append(confidence(for:)) }
        }
        // Loop Once
        let verticesString = vertices.enumerated().map { vertexIndex, _ in
            // Our different elements on the same line separated by a space
            verticesProcessors.map { processor in processor(vertexIndex) }.joined(separator: " ")
        }

        // MARK: Faces
        var facesProcessors = [((Int) -> String)]()

        // Check once
        if hasTriangles {
            facesProcessors.append(triangle(for:))
        }
        // Loop Once
        let faceStrings = triangles.enumerated().map { triangleIndex, _ in
            facesProcessors.map { processor in processor(triangleIndex) }.joined(separator: " ")
        }

        return [verticesString.joined(separator: "\n"),
                faceStrings.joined(separator: "\n")].joined(separator: "\n")
    }
}

extension Float {
    fileprivate var rgb: UInt {
        UInt(self * 255)
    }
}

extension PolygonFileFormat.HeaderLine: AsciiRepresentable {
    fileprivate var ascii: String { "\(key) \(value ?? "")" }
}

extension Sequence where Iterator.Element == AsciiRepresentable {
    fileprivate func joinedAsciiRepresentation(separator: String = "\n") -> String {
        map { $0.ascii }
            .joined(separator: separator)
    }
}

extension UTType {
    public static let polygon = UTType.init(filenameExtension: "ply")!
}
