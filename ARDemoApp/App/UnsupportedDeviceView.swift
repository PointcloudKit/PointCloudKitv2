//
//  UnsupportedDeviceView.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 11/05/2021.
//

import SwiftUI

struct UnsupportedDeviceView: View {
    var body: some View {
        ZStack {
            Color.black
            Label(
                title: {
                    Text("This application necessitate a LiDAR capable device. It seems that this device does not support this fonctionnality.")
                        .font(.callout)
                        .foregroundColor(.bone)
                },
                icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.amazon)
                }
            )

        }
    }
}

struct UnsupportedDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        UnsupportedDeviceView()
    }
}
