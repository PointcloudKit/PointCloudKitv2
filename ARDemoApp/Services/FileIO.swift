//
//  FileIO.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 2/4/2021.
//

import Foundation

struct FileIO {
    func documentFolderURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
    }
}
