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
import PointCloudRendererService
import PointCloudProcessorService
import Combine

struct PLYFile: FileDocument {
    private let cancellables = Set<AnyCancellable>()
    // tell the system we support only plain text
    static let readableContentTypes = [UTType.polygon]

    @State private(set) var writtingToDisk = false
    @State private(set) var writeToDiskProgress = 0.0

    // by default our document is empty
    private(set) var particles: [ParticleUniforms]

    // a simple initializer that creates new, empty documents
    init(particles: [ParticleUniforms] = []) {
        self.particles = particles
    }

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        fatalError("Not supported")
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let timeInterval = Date().timeIntervalSince1970 * 1000
        let filename = String(format: "export_%d.ply", timeInterval)
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(filename)

        writeToDiskProgress = 0
        writtingToDisk = true

        write(particles, to: temporaryFileURL, progressHandler: { (progress) in
            writeToDiskProgress = progress
            if progress == 1 {
                writtingToDisk = false
            }
        })
        return try FileWrapper(url: temporaryFileURL)
    }

    private func generatePlyFileAsciiData(using particles: [ParticleUniforms]) -> Data? {
        // MARK: - Vertices
        let comments = ["author: ArDemoApp",
                        "object: colored point cloud scan with confidence"]
        return PolygonFileFormat.generateAsciiData(using: particles, comments: comments)
    }

    private func write(_ particles: [ParticleUniforms], to url: URL, progressHandler: @escaping (Double) -> Void) {
        writtingToDisk = true
        guard let data = generatePlyFileAsciiData(using: particles) else { fatalError() }
        progressHandler(0.5)
        do {
            try data.write(to: url, options: [])
        } catch { fatalError(error.localizedDescription) }
        progressHandler(1.0)
        writtingToDisk = false
    }
}
