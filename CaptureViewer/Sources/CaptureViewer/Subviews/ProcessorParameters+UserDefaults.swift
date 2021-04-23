//
//  ProcessorParameters+UserDefaults.swift
//  
//
//  Created by Alexandre Camilleri on 23/04/2021.
//

import Foundation
import PointCloudProcessorService

// MARK: - User Default read write for user parameters
extension ProcessorParameters {

    private static let userDefaultKey = "com.pointCloudKit.processorParameters"

    static var fromUserDefaultOrNew: ProcessorParameters {
        guard let parametersData = UserDefaults.standard.object(forKey: Self.userDefaultKey) as? Data,
              let decodedParamters = try? JSONDecoder().decode(ProcessorParameters.self, from: parametersData)
        else {
            return ProcessorParameters()
        }
        return decodedParamters
    }

    func writeToUserDefault() {
        guard let encoded = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(encoded, forKey: Self.userDefaultKey)
    }
}
