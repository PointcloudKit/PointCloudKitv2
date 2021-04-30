//
//  CaptureViewerModel.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import Combine
import Common
import PointCloudRendererService
import ProcessorService


final public class CaptureViewerModel: ObservableObject {



    @Published var normalsAvailable = false
    @Published var undoAvailable = false
    @Published var exportPlyAvailable = false

    @Published var vertexCount = 0
    @Published var normalCount = 0
    @Published var triangleCount = 0


//    // Before in other
//    private func vertexProcessing(of object: Object3D, with processors: [VertexProcessor]) -> Future<Object3D, ProcessorServiceError> {
//        processing = true
//        return Future { promise in
//            process(object: object, with: processors)
//                .sink(receiveCompletion: { result in
//                    switch result {
//                    case .finished:
//                        return
//                    case let .failure(error):
//                        print(error.localizedDescription)
//                        return
//                    }
//                }, receiveValue: { object in
//                    self.capture.reloadBufferContent(with: object.particles())
//                    DispatchQueue.main.async {
//                        self.lastObject = self.object
//                        self.object = object
//                        self.processing = false
//                    }
//                })
//                .store(in: &self.cancellables)
//        }
//    }
//
//    private func faceProcessing(with processors: [FaceProcessor]) {
//        processing = true
//        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
//            guard let self = self, let plyFile = self.plyFile() else { return }
//            self.processor.process(plyFile, with: processors)
//                .sink(receiveCompletion: { result in
//                    switch result {
//                    case .finished:
//                        return
//                    case let .failure(error):
//                        print(error.localizedDescription)
//                        return
//                    }
//                }, receiveValue: { object in
//                    self.capture.reloadBufferContent(with: object.particles())
//                    DispatchQueue.main.async {
//                        self.lastObject = self.object
//                        self.object = object
//                        self.processing = false
//                    }
//                })
//                .store(in: &self.cancellables)
//        }
//    }

    // MARK: - Methods

//    public init(capture: PointCloudCapture) {
//        self.capture = capture
//
//        // Generate Object
//        convert(capture: capture)
//            .subscribe(on: DispatchQueue.global())
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { [weak self] object in
//                self?.object = object
//            })
//            .store(in: &cancellables)
//
//        $object
//            .receive(on: DispatchQueue.main)
//            .handleEvents(receiveOutput: { [weak self] object in
//                guard let self = self, let object = object else { return }
//                self.vertexCount = object.vertices.count
//                self.normalCount = object.vertexNormals.count
//                self.triangleCount = object.triangles.count
//                self.normalsAvailable = object.vertexNormals.count != 0
//            })
//            .map { object in object != nil }
//            .assign(to: &$exportPlyAvailable)
//
//        $lastObject
//            .receive(on: DispatchQueue.main)
//            .map { $0 != nil }
//            .assign(to: &$undoAvailable)
//
//        $exportProgress
//            .receive(on: DispatchQueue.main)
//            .map { $0 != 1.0 }
//            .assign(to: &$exporting)
//    }

//    private func convert(capture: PointCloudCapture) -> Future<Object3D, Never> {
//        Future { promise in
//            // Filter out the
//            let particles = capture.buffer.getMemoryRepresentationCopy(for: capture.count).filter { particle in
//                Int32(particle.confidence) >= capture.confidenceTreshold.rawValue
//            }
//            let object = Object3D(vertices: particles.map(\.position),
//                                  vertexConfidence: particles.map({ particle in UInt(particle.confidence) }),
//                                  vertexColors: particles.map(\.color))
//            promise(.success(object))
//        }
//    }

}

// MARK: - Internals
extension CaptureViewerModel {

}
