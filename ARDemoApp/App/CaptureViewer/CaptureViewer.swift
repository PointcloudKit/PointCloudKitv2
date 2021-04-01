//
//  AssetViewer.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import SceneKit
import PointCloudRendererService

struct CaptureViewer: View {

    @StateObject var model: CaptureViewerModel

    let viewModel = CaptureViewerViewModel()

    var scene: SCNScene {
        let scene = viewModel.generateScene(from: model.capture)
        let cameraNode = self.cameraNode

//        cameraNode.position = scene.rootNode.
        cameraNode.look(at: scene.rootNode.position)
        cameraNode.position.z += 10
//        cameraNode.rotation = SCNVector4Make(1, 0, 0, .pi/2)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ambientLightNode)
        scene.background.contents = UIColor.black

        return scene
    }

    var cameraNode: SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.name = "CameraNode"
        return cameraNode
    }

    var ambientLightNode: SCNNode {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        return ambientLightNode
    }

    var body: some View {
        ZStack {
            SceneView(scene: scene,
                      pointOfView: scene.rootNode.childNode(withName: "CameraNode", recursively: false),
                      options: [
                        .allowsCameraControl,
                        .autoenablesDefaultLighting,
                        .temporalAntialiasingEnabled
                      ])

            VStack {
                Spacer()
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
    }
}
