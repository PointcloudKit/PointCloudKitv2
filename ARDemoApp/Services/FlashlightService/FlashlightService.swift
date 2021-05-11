//
//  FlashlightService.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 30/04/2021.
//

import AVKit

final class FlashlightService {
    @discardableResult
    class func toggleFlashlight() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch
        else { return false }

        do {
            try device.lockForConfiguration()
            switch device.torchMode {
            case .off:
                device.torchMode = .on
            default:
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            return false
        }
        return device.torchMode == .on
    }
}
