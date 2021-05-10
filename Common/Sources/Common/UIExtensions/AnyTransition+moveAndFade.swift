//
//  File.swift
//  
//
//  Created by Alexandre Camilleri on 21/04/2021.
//

import SwiftUI

extension AnyTransition {
    public static var moveAndFade: AnyTransition {
        AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
    }
}
