//
//  HomeModel.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 12/05/2021.
//

import Foundation
import PointCloudRendererService
import Metal.MTLDevice

final class HomeModel: ObservableObject {
    @Published var renderingService = RenderingService(metalDevice: MTLCreateSystemDefaultDevice()!)
}
