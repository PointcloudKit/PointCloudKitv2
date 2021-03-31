//
//  CaptureToggleStyle.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 31/03/2021.
//

import SwiftUI

/// A style for a toggle to represent a Capture On/Off toggle UI element
struct CaptureToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "stop.circle" : "restart.circle")
                .font(.system(size: 64, weight: .light))
                .onTapGesture { configuration.isOn.toggle() }
                .foregroundColor(configuration.isOn ? Color.red : Color.white)
        }
    }
}
