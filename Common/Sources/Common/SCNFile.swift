//
//  SCNFile.swift
//  
//
//  Created by Alexandre Camilleri on 09/04/2021.
//

import Foundation
import SwiftUI
import SceneKit.SCNScene
import UniformTypeIdentifiers.UTType

public struct SCNFile: FileDocument {
    // tell the system we support only plain text
    public static let readableContentTypes = [UTType.sceneKitScene]

    @State public private(set) var writtingToDisk = false
    @State public private(set) var writeToDiskProgress = 0.0

    // by default our document is empty
    private var scene: SCNScene

    // a simple initializer that creates new, empty documents
    public init(scene: SCNScene = SCNScene()) {
        self.scene = scene
    }

    // this initializer loads data that has been saved previously
    public init(configuration: ReadConfiguration) throws {
        fatalError("Not supported")
    }

    // this will be called when the system wants to write our data to disk
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let timeInterval = Date().timeIntervalSince1970 * 1000
        let filename = String(format: "export_%d.scn", timeInterval)
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(filename)

        writeToDiskProgress = 0
        writtingToDisk = true

        write(scene: scene, to: temporaryFileURL) { (progress) in
            writeToDiskProgress = progress
            if progress == 1 {
                writtingToDisk = false
            }
        }
        return try FileWrapper(url: temporaryFileURL)
    }

    func write(scene: SCNScene, to url: URL, progressHandler: @escaping (Double) -> Void) {
        scene.write(to: url, options: nil, delegate: nil) { (progress, error, _) in
            if error != nil {
                fatalError("handle error here")
            }
            progressHandler(Double(progress))
        }
    }
}
