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

    let captureViewerModel = CaptureViewerControlModel(processorService: ProcessorService(), exportService: ExportService())

    let sceneRendererModel = SceneRenderModel()

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
}

struct CaptureViewer: View {

    @EnvironmentObject var model: CaptureViewerModel

    let particleBuffer: ParticleBufferWrapper
    let initialCaptureParticleCount: Int
    let confidenceTreshold: ConfidenceTreshold

    @State var object: Object3D = Object3D()

    public var body: some View {
        ZStack {
            SceneRender(particleBuffer: particleBuffer,
                        particleCount: object.vertices.count)
                .environmentObject(model.sceneRendererModel)

            VStack {

                Metrics(currentPointCount: object.vertices.count,
                        currentNormalCount: object.vertexNormals.count,
                        currentFaceCount: object.triangles.count,
                        activity: true)

                Spacer()

                CaptureViewerControl(particleBuffer: particleBuffer,
                                     object: $object,
                                     confidenceTreshold: confidenceTreshold)
                    .environmentObject(model.captureViewerModel)
            }

        }
        .navigationBarTitle("Viewer", displayMode: .inline)
        .onAppear {
            CaptureViewerModel.convert(particleBuffer, particleCount: initialCaptureParticleCount)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { object in
                    self.object = object
                })
                .store(in: &model.cancellables)
        }
        .onDisappear {
            model.cancellables.forEach { cancellable in cancellable.cancel() }
        }
    }
}
