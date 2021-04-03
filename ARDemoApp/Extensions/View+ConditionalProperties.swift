//
//  View+HiddenConditionally.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 31/03/2021.
//

import SwiftUI

extension View {
    func hiddenConditionally(isHidden: Bool) -> some View {
        isHidden ? AnyView(hidden().disabled(true)) : AnyView(disabled(false))
    }

    func disabledConditionally(disabled: Bool) -> some View {
        AnyView(self.disabled(disabled))
    }
}
