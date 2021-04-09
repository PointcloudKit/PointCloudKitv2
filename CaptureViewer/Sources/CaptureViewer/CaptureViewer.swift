//
//  AssetViewer.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import SceneKit
import PointCloudRendererService
import Common

public struct CaptureViewer: View {

    private let cameraNodeIdentifier = "com.pointCloudKit.nodes.camera"

    @StateObject public var model: CaptureViewerModel

    let viewModel = CaptureViewerViewModel()

    @State private var scnExportFile = SCNFile()
    @State private var showingSCNExporter = false
    @State private var showingPLYExporter = false

    var scene: SCNScene {
        let scene = viewModel.generateScene(from: model.capture)
        let cameraNode = self.cameraNode

        cameraNode.look(at: scene.rootNode.position)
        cameraNode.position.z += 5
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ambientLightNode)
        scene.background.contents = UIColor.black

        return scene
    }

    var cameraNode: SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.name = cameraNodeIdentifier
        return cameraNode
    }

    var ambientLightNode: SCNNode {
        let ambientLightNode = SCNNode()
        let light = SCNLight()

        light.type = .ambient
        ambientLightNode.light = light
        return ambientLightNode
    }

    // Seems hacky, I wish it expose the auto generated init automatically
    public init(model: CaptureViewerModel) {
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        ZStack {
            SceneView(scene: scene,
                      pointOfView: scene.rootNode.childNode(withName: cameraNodeIdentifier, recursively: false),
                      options: [
                        .allowsCameraControl,
                        .autoenablesDefaultLighting,
                        .temporalAntialiasingEnabled
                      ])

            VStack {

                Spacer()

                ProgressView("Exporting…", value: scnExportFile.writeToDiskProgress, total: 1)
                    .hiddenConditionally(isHidden: !scnExportFile.isWrittingToDisk)
                    .fileExporter(isPresented: $showingSCNExporter, document: scnExportFile, contentType: .sceneKitScene, onCompletion: { _ in })

                HStack(alignment: .top, spacing: 0, content: {
                    Label(
                        title: { Text("\(model.capture.count)") },
                        icon: {
                            Image(systemName: "aqi.medium")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    )
                    .padding()

                    Spacer()
                })
            }
        }
        .navigationBarTitle("Viewer", displayMode: .inline)
        .toolbar(content: {
            Button("Export") {
                scnExportFile = SCNFile(scene: scene)
                showingSCNExporter = true
            }
        })
    }
}
