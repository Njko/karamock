//
//  StretchyView.swift
//  Karamock
//
//  Created by A422GQ on 26/07/2026.
//

import SwiftUI

extension View {
    func stretchy() -> some View {
        #if os(iOS)
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)
            
            let newHeight = currentHeight + positiveOffset
            let scaleFactor = newHeight / currentHeight
            
            return effect.scaleEffect(
                x: scaleFactor,
                y: scaleFactor,
                anchor: .bottom
            )
            
        }
        #else
        self
        #endif
    }
}
