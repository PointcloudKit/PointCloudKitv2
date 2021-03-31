//
//  View+HiddenConditionally.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 31/03/2021.
//

import SwiftUI

extension View {
    func hiddenConditionally(isHidden: Bool) -> some View {
        return isHidden ? AnyView(hidden().disabled(true)) : AnyView(disabled(false))
    }
}
