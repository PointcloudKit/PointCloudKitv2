//
//  ProcessorServiceError.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 10/05/2021.
//

import Foundation

public enum ProcessorServiceError: Error, LocalizedError {
    case unknown
    case pythonThreadState
    case missingNormals

    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "Something went wrong"
        case .pythonThreadState:
            return "The underlying python module used for processing encountered some issues with memory management"
        case .missingNormals:
            return "In order to be able to apply this processing, the vertices normals need to be known. Consider doing a \"normal estimation\" pass in order to compute them"
        }
    }
}
