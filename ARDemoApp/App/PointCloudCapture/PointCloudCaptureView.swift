//
//  PointCloudCaptureView.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 26/03/2021.
//

import SwiftUI

struct PointCloudCaptureView: View {
    var body: some View {

        PointCloudCaptureRenderingView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct PointCloudCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        PointCloudCaptureView()
    }
}
