//
//  SceneManager.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import Foundation
import SceneKit
import Combine
import Common
import PointCloudRendererService

enum NodeIdentifier: String {
    case camera = "com.pointCloudKit.nodes.camera"
    case pointCloudRoot = "com.pointCloudKit.nodes.pointCloudRootRoot"
}

final class SceneManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published var rendering = false

    // Give access to the capture
    unowned var renderingService: PointCloudRendererService

    init(renderingService: PointCloudRendererService) {
        self.renderingService = renderingService
    }

    func start() {
        // Generate Object
        convert(capture: capture)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] object in
                self?.object = object
            })
            .store(in: &cancellables)

        $object
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] object in
                guard let self = self, let object = object else { return }
                self.vertexCount = object.vertices.count
                self.normalCount = object.vertexNormals.count
                self.triangleCount = object.triangles.count
                self.normalsAvailable = object.vertexNormals.count != 0
            })
            .map { object in object != nil }
            .assign(to: &$exportPlyAvailable)

        $lastObject
            .receive(on: DispatchQueue.main)
            .map { $0 != nil }
            .assign(to: &$undoAvailable)

        $exportProgress
            .receive(on: DispatchQueue.main)
            .map { $0 != 1.0 }
            .assign(to: &$exporting)
    }

    func generateScene(from capture: PointCloudCapture) -> SCNScene {
        rendering = true
        let scene = SCNScene()
        // Create point cloud nodes and add to the scene
        capture.generatePointCloudNode()
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (pointCloudRootNode, vertexCount) in
                self?.rendering = false
                self?.vertexCount = vertexCount
                scene.rootNode.addChildNode(pointCloudRootNode)
            }
            .store(in: &cancellables)
        return scene
    }

    // MARK: - Scene Elements Generators

    private func generateScene(from capture: PointCloudCapture) -> SCNScene {
        let scene = generateScene(from: capture)
        let cameraNode = Self.makeCameraNode()

        cameraNode.look(at: scene.rootNode.position)
        cameraNode.position.z += 5
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(Self.makeAmbientLightNode())
        scene.background.contents = UIColor.black
        return scene
    }

    private class func makeCameraNode() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.name = NodeIdentifier.camera.rawValue
        return cameraNode
    }

    private class func makeAmbientLightNode() -> SCNNode {
        let ambientLightNode = SCNNode()
        let light = SCNLight()

        light.type = .ambient
        ambientLightNode.light = light
        return ambientLightNode
    }
}


//import Combine
//import Common
//import PointCloudRendererService
//import ProcessorService
//
//
//final public class CaptureViewerModel: ObservableObject {
//
//    @Published var normalsAvailable = false
//    @Published var undoAvailable = false
//    @Published var exportPlyAvailable = false
//
//    @Published var vertexCount = 0
//    @Published var normalCount = 0
//    @Published var triangleCount = 0
//
//
////    // Before in other
////    private func vertexProcessing(of object: Object3D, with processors: [VertexProcessor]) -> Future<Object3D, ProcessorServiceError> {
////        processing = true
////        return Future { promise in
////            process(object: object, with: processors)
////                .sink(receiveCompletion: { result in
////                    switch result {
////                    case .finished:
////                        return
////                    case let .failure(error):
////                        print(error.localizedDescription)
////                        return
////                    }
////                }, receiveValue: { object in
////                    self.capture.reloadBufferContent(with: object.particles())
////                    DispatchQueue.main.async {
////                        self.lastObject = self.object
////                        self.object = object
////                        self.processing = false
////                    }
////                })
////                .store(in: &self.cancellables)
////        }
////    }
////
////    private func faceProcessing(with processors: [FaceProcessor]) {
////        processing = true
////        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
////            guard let self = self, let plyFile = self.plyFile() else { return }
////            self.processor.process(plyFile, with: processors)
////                .sink(receiveCompletion: { result in
////                    switch result {
////                    case .finished:
////                        return
////                    case let .failure(error):
////                        print(error.localizedDescription)
////                        return
////                    }
////                }, receiveValue: { object in
////                    self.capture.reloadBufferContent(with: object.particles())
////                    DispatchQueue.main.async {
////                        self.lastObject = self.object
////                        self.object = object
////                        self.processing = false
////                    }
////                })
////                .store(in: &self.cancellables)
////        }
////    }
//
//    // MARK: - Methods
//
////    public init(capture: PointCloudCapture) {
////        self.capture = capture
////
////        // Generate Object
////        convert(capture: capture)
////            .subscribe(on: DispatchQueue.global())
////            .receive(on: DispatchQueue.main)
////            .sink(receiveValue: { [weak self] object in
////                self?.object = object
////            })
////            .store(in: &cancellables)
////
////        $object
////            .receive(on: DispatchQueue.main)
////            .handleEvents(receiveOutput: { [weak self] object in
////                guard let self = self, let object = object else { return }
////                self.vertexCount = object.vertices.count
////                self.normalCount = object.vertexNormals.count
////                self.triangleCount = object.triangles.count
////                self.normalsAvailable = object.vertexNormals.count != 0
////            })
////            .map { object in object != nil }
////            .assign(to: &$exportPlyAvailable)
////
////        $lastObject
////            .receive(on: DispatchQueue.main)
////            .map { $0 != nil }
////            .assign(to: &$undoAvailable)
////
////        $exportProgress
////            .receive(on: DispatchQueue.main)
////            .map { $0 != 1.0 }
////            .assign(to: &$exporting)
////    }
//
////    private func convert(capture: PointCloudCapture) -> Future<Object3D, Never> {
////        Future { promise in
////            // Filter out the
////            let particles = capture.buffer.getMemoryRepresentationCopy(for: capture.count).filter { particle in
////                Int32(particle.confidence) >= capture.confidenceTreshold.rawValue
////            }
////            let object = Object3D(vertices: particles.map(\.position),
////                                  vertexConfidence: particles.map({ particle in UInt(particle.confidence) }),
////                                  vertexColors: particles.map(\.color))
////            promise(.success(object))
////        }
////    }
//
//}
