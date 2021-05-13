//
//  CaptureViewerControlsModel.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 03/05/2021.
//

import Foundation
import Common
import PointCloudRendererService
import Combine

final class CaptureViewerControlsModel: ObservableObject {
    public var cancellables = Set<AnyCancellable>()

    let exportService: ExportService
    let particleBuffer: ParticleBufferWrapper
    let confidenceThreshold: ConfidenceThreshold
    let captureViewerParametersModel: CaptureViewerParametersModel

    init(
        exportService: ExportService,
        particleBuffer: ParticleBufferWrapper,
        confidenceThreshold: ConfidenceThreshold
    ) {
        self.exportService = exportService
        self.particleBuffer = particleBuffer
        self.confidenceThreshold = confidenceThreshold
        captureViewerParametersModel = CaptureViewerParametersModel(particleBuffer: particleBuffer,
                                                                    processorService: ProcessorService())
    }
}
