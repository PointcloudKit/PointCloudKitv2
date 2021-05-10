//
//  View+HiddenConditionally.swift
//  ARDemoApp
//
//  Created by Alexandre Camilleri on 31/03/2021.
//

import SwiftUI

extension View {
    public func hiddenConditionally(_ hidden: Bool) -> some View {
        hidden ? AnyView(self.hidden().disabled(true)) : AnyView(disabled(false))
    }
}
