//
//  HomeView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 24/03/2021.
//

import SwiftUI

struct HomeView: View {

    @StateObject var model = HomeModel()

    var body: some View {
        CaptureView()
            .environmentObject(CaptureModel(renderingService: model.renderingService))
    }
}
