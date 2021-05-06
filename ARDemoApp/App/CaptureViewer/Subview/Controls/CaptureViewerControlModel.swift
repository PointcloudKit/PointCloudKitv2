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
    public var cancellables = Set<AnyCancellable>()

    let processorService: ProcessorService
    let exportService: ExportService

    init(processorService: ProcessorService, exportService: ExportService) {
        self.processorService = processorService
        self.exportService = exportService
    }

    // MARK: - Point Cloud Processing operations - Parameters are from the `ProcessorParameters` in Model
    func voxelDownsampling(_ object: Object3D, parameters: ProcessorParameters.VoxelDownSampling) -> Future<Object3D, ProcessorServiceError> {
        return processorService.voxelDownsampling(of: object, with: parameters)
    }

    func statisticalOutlierRemoval(_ object: Object3D, parameters: ProcessorParameters.OutlierRemoval.Statistical) -> Future<Object3D, ProcessorServiceError> {
        return processorService.statisticalOutlierRemoval(of: object, with: parameters)
    }

    func radiusOutlierRemoval(_ object: Object3D, parameters: ProcessorParameters.OutlierRemoval.Radius) -> Future<Object3D, ProcessorServiceError> {
        return processorService.radiusOutlierRemoval(of: object, with: parameters)
    }

    func normalsEstimation(_ object: Object3D, parameters: ProcessorParameters.NormalsEstimation) -> Future<Object3D, ProcessorServiceError> {
       return processorService.normalsEstimation(of: object, with: parameters)
    }

    func poissonSurfaceReconstruction(_ object: Object3D, parameters: ProcessorParameters.SurfaceReconstruction.Poisson) -> Future<Object3D, ProcessorServiceError> {
        return processorService.poissonSurfaceReconstruction(of: object, with: parameters)
    }
}
