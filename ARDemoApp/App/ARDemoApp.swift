//
//  ARDemoApp.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 24/03/2021.
//

import SwiftUI
import ARKit
import Open3DSupport
import NumPySupport
import PythonSupport

@main
struct ARDemoApp: App {

    @State var lidarCapableDevice = false

    init() {
        #if !targetEnvironment(simulator)
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else { return}
        #endif
        lidarCapableDevice = true
        // Initialize Python environment
        PythonSupport.initialize()
        Open3DSupport.sitePackagesURL.insertPythonPath()
        NumPySupport.sitePackagesURL.insertPythonPath()

        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.bone)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.bone)]
        UINavigationBar.appearance().isTranslucent = true
    }

    @ViewBuilder
    var body: some Scene {
        WindowGroup {
            if lidarCapableDevice {
                HomeView()
            } else {
                UnsupportedDeviceView()
            }
        }
    }
}
