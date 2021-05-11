//
//  ExportService.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 30/04/2021.
//

import Foundation
import Common
import SceneKit

final class ExportService: ObservableObject {

    @Published var exportProgress = 1.0
    @Published var info = "Exporting..."
    @Published var exporting = false

    func generateSCNFile(from scene: SCNScene) -> SCNFile {
        let file = SCNFile(scene: scene)
        info = "Exporting SCN..."
        file.$writeToDiskProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$exportProgress)
        file.$writtingToDisk
            .receive(on: DispatchQueue.main)
            .assign(to: &$exporting)
        return file
    }

    func generatePLYFile(from object: Object3D) -> PLYFile {
        let file = PLYFile(object: object)
        info = "Exporting PLY..."
        file.$writeToDiskProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$exportProgress)
        file.$writtingToDisk
            .receive(on: DispatchQueue.main)
            .assign(to: &$exporting)
        return file
    }
}
