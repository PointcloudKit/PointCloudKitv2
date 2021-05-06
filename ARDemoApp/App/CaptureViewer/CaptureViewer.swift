//
//  CaptureViewer.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 01/04/2021.
//

import SwiftUI
import Common
import PointCloudRendererService
import Combine

final class CaptureViewerModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()

    let particleBuffer: ParticleBufferWrapper
    let particleCount: Int
    let confidenceTreshold: ConfidenceTreshold

    @Published var object: Object3D = Object3D()

    lazy var sceneRenderModel: SceneRenderModel = {
        SceneRenderModel(particleBuffer: particleBuffer, initialParticleCount: particleCount)
    }()

    lazy var captureControlModel: CaptureViewerControlModel = {
        CaptureViewerControlModel(processorService: ProcessorService(), exportService: ExportService())
    }()

    // MARK: - PointCloudKit -> PointCloudKit
    class func convert(_ particleBuffer: ParticleBufferWrapper, particleCount: Int) -> Future<Object3D, Never> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                let particles = particleBuffer.buffer.getMemoryRepresentationCopy(for: particleCount)
                let object = Object3D(vertices: particles.map(\.position),
                                      vertexConfidence: particles.map({ particle in UInt(particle.confidence) }),
                                      vertexColors: particles.map(\.color))
                promise(.success(object))
            }
        }
    }

    init(particleBuffer: ParticleBufferWrapper, particleCount: Int, confidenceTreshold: ConfidenceTreshold) {
        self.particleBuffer = particleBuffer
        self.particleCount = particleCount
        self.confidenceTreshold = confidenceTreshold

        sceneRenderModel.particleCount = particleCount

        CaptureViewerModel.convert(particleBuffer, particleCount: particleCount)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { object in
                self.object = object
//                self.sceneRenderModel.particleCount = object.vertices.count
                self.sceneRenderModel.updateScene(particleCount: object.vertices.count)
            })
            .store(in: &cancellables)
    }
}

struct CaptureViewer: View {

    @EnvironmentObject var model: CaptureViewerModel

    public var body: some View {
        ZStack {
            SceneRender()

            VStack {

                Metrics(currentPointCount: model.object.vertices.count,
                        currentNormalCount: model.object.vertexNormals.count,
                        currentFaceCount: model.object.triangles.count,
                        activity: true)

                Spacer()

                #warning("move these to the model")
                CaptureViewerControl(particleBuffer: model.particleBuffer,
                                     object: $model.object,
                                     confidenceTreshold: model.confidenceTreshold)
            }

        }
        .navigationBarTitle("Viewer", displayMode: .inline)
        .environmentObject(model.sceneRenderModel)
        .environmentObject(model.captureControlModel)
    }
}
