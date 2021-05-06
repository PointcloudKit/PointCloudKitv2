//
//  HomeView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 24/03/2021.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Capture()
            .environmentObject(CaptureModel())
    }
}
