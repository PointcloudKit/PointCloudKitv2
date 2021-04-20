//
//  PolygonFileFormat.swift
//  Metra
//
//  Created by Alexandre Camilleri on 16/12/2020.
//

import Foundation
import PointCloudRendererService
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
    }

    enum Keyword: String {
        case start = "ply", end = "end_header"
        case format, comment, element, property
    }

    enum Element: String {
        case vertex
    }

    enum Format: String {
        case ascii
        //        case bin
    }

    enum Property: String {
        case positionX = "x", positionY = "y", positionZ = "z"
        case redComponent = "red", greenComponent = "green", blueComponent = "blue"
        case confidence = "confidence"
    }

    enum PropertyType: String {
        case float, uchar
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
    public static func generateAsciiData(using particles: [ParticleUniforms], comments: [String]? = nil) -> Data? {
        var header = [HeaderLine]()

        header.append(.start)
        header.append(.init(format: .ascii, version: "1.0"))
        // Add comments
        comments?.forEach({ (comment) in
            header.append(.init(comment: comment))
        })
        // Define Vertice property, if contains any
        if !particles.isEmpty {
            header.append(.init(element: .vertex, count: particles.count))
            header.append(.init(property: .positionX, type: .float))
            header.append(.init(property: .positionY, type: .float))
            header.append(.init(property: .positionZ, type: .float))
            header.append(.init(property: .redComponent, type: .uchar))
            header.append(.init(property: .greenComponent, type: .uchar))
            header.append(.init(property: .blueComponent, type: .uchar))
            header.append(.init(property: .confidence, type: .uchar))
        }
        header.append(.end)

        var lines = [AsciiRepresentable]()

        lines.append(contentsOf: header)
        lines.append(contentsOf: particles)

        let asciiData = lines
            .joinedAsciiRepresentation()
            .data(using: .ascii)

        return asciiData
    }
}

private protocol AsciiRepresentable {
    var ascii: String { get }
}

extension ParticleUniforms: AsciiRepresentable {
    #warning("Improve these conversion - just hacking now")
    fileprivate var ascii: String { "\(position.x) \(position.y) \(position.z) \(Int(color.x * 255)) \(Int(color.y * 255)) \(Int(color.z * 255)) \(Int(confidence))" }
}

extension PolygonFileFormat.HeaderLine: AsciiRepresentable {
    fileprivate var ascii: String { "\(key) \(value ?? "")" }
}

extension Sequence where Iterator.Element == AsciiRepresentable {
    fileprivate func joinedAsciiRepresentation(separator: String = "\n") -> String {
        map { "\($0.ascii)" }
            .joined(separator: separator)
    }
}

extension UTType {
    public static let polygon = UTType.init(filenameExtension: "ply")!
}
