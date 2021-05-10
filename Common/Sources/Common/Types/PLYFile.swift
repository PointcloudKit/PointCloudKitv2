//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 19/04/2021.
//

import Foundation
import SwiftUI
import SceneKit.SCNScene
import UniformTypeIdentifiers.UTType
import Combine

public final class PLYFile: FileDocument, ObservableObject {
    private let cancellables = Set<AnyCancellable>()
    // tell the system we support only plain text
    public static let readableContentTypes = [UTType.polygon]
    public static let writableContentTypes = [UTType.polygon]

    @Published public private(set) var writtingToDisk = false
    @Published public private(set) var writeToDiskProgress = 0.0

    // by default our document is empty
    public private(set) var object: Object3D

    // a simple initializer that creates new, empty documents
    public init(object: Object3D = Object3D()) {
        self.object = object
    }

    // this initializer loads data that has been saved previously
    public init(configuration: ReadConfiguration) throws {
        fatalError("Not supported")
    }

    // this will be called when the system wants to write our data to disk
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let timeInterval = Date().timeIntervalSince1970 * 1000
        let filename = String(format: "export_%d.ply", timeInterval)
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(filename)

        writeToDiskProgress = 0
        write(object, to: temporaryFileURL, progressHandler: { [weak self] (progress) in
            self?.writeToDiskProgress = progress
            if progress == 1 {
                self?.writtingToDisk = false
            }
        })
        return try FileWrapper(url: temporaryFileURL)
    }

    private func generatePlyFileAsciiData(from object: Object3D) -> Data? {
        // MARK: - Vertices
        let comments = ["author: ArDemoApp",
                        "object: colored point cloud scan with confidence"]
        return PolygonFileFormat.generateAsciiData(using: object, comments: comments)
    }

    private func write(_ object: Object3D, to url: URL, progressHandler: @escaping (Double) -> Void) {
        guard let data = generatePlyFileAsciiData(from: object) else { fatalError() }
        progressHandler(0.5)
        do {
            try data.write(to: url, options: [])
        } catch {
            fatalError(error.localizedDescription)
        }
        progressHandler(1.0)
    }
}
