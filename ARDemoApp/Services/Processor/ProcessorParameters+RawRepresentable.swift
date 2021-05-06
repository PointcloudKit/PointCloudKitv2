//
//  ProcessorParameters+RawRepresentable.swift
//
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import Foundation

// MARK: - User Default read write for user parameters
extension ProcessorParameters: RawRepresentable {
    public static let storageKey = "com.pointCloudKit.processorParameters"

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: String.Encoding.utf8),
            let result = try? JSONDecoder().decode(ProcessorParameters.self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return result
    }
}
