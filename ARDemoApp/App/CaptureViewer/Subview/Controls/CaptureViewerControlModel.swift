//
//  CaptureViewerControlModel.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 03/05/2021.
//

import Foundation
import Common
import PointCloudRendererService
import Combine

final class CaptureViewerControlModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    let particleBuffer: ParticleBufferWrapper

    private let processorService = ProcessorService()
    let exportService = ExportService()

    var object: Object3D = Object3D()
    
    @Published var lastObject: Object3D?
    @Published var undoAvailable: Bool = false
    @Published var processing = false
    @Published var exporting = false

    init(particleBuffer: ParticleBufferWrapper) {
        self.particleBuffer = particleBuffer
    }

    func initialize() {
        processing = true

        // Generate Object
        Self.convert(particleBuffer)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] object in
                self?.object = object
                self?.processing = false
            })
            .store(in: &cancellables)

        $lastObject
            .receive(on: DispatchQueue.main)
            .map { object in object != nil }
            .assign(to: &$undoAvailable)
    }

    func undo() {
        guard let lastObject = lastObject else { return }
        processing = true
        object = lastObject
        self.lastObject = nil
        processing = false
    }

    private func update(with object: Object3D) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.particleBuffer.buffer.assign(with: object.particles())
        }
        lastObject = self.object
        self.object = object
        processing = false
    }

    // MARK: - Point Cloud Processing operations - Parameters are from the `ProcessorParameters` in Model
    func voxelDownsampling(parameters: ProcessorParameters.VoxelDownSampling) {
        processing = true
        processorService.voxelDownsampling(of: object, with: parameters)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {_ in},
                  receiveValue: { [weak self] object in
                    self?.update(with: object)
                  })
            .store(in: &cancellables)
    }

    func statisticalOutlierRemoval(parameters: ProcessorParameters.OutlierRemoval.Statistical) {
        processing = true
        processorService.statisticalOutlierRemoval(of: object, with: parameters)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {_ in},
                  receiveValue: { [weak self] object in
                    self?.update(with: object)
                  })
            .store(in: &cancellables)
    }

    func radiusOutlierRemoval(parameters: ProcessorParameters.OutlierRemoval.Radius) {
        processing = true
        processorService.radiusOutlierRemoval(of: object, with: parameters)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {_ in},
                  receiveValue: { [weak self] object in
                    self?.update(with: object)
                  })
            .store(in: &cancellables)
    }

    func normalsEstimation(parameters: ProcessorParameters.NormalsEstimation) {
        processing = true
        processorService.normalsEstimation(of: object, with: parameters)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {_ in},
                  receiveValue: { [weak self] object in
                    self?.update(with: object)
                  })
            .store(in: &cancellables)
    }

    func poissonSurfaceReconstruction(parameters: ProcessorParameters.SurfaceReconstruction.Poisson) {
        // FAUT KI YE LE NORMAL
        processing = true
        processorService.poissonSurfaceReconstruction(of: object, with: parameters)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {_ in},
                  receiveValue: { [weak self] object in
                    self?.update(with: object)
                  })
            .store(in: &cancellables)
    }

    // MARK: - PointCloudKit -> PointCloudKit
    private class func convert(_ particleBuffer: ParticleBufferWrapper) -> Future<Object3D, Never> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                let particles = particleBuffer.buffer.getMemoryRepresentationCopy(for: particleBuffer.count)
                let object = Object3D(vertices: particles.map(\.position),
                                      vertexConfidence: particles.map({ particle in UInt(particle.confidence) }),
                                      vertexColors: particles.map(\.color))
                promise(.success(object))
            }
        }
    }
}
