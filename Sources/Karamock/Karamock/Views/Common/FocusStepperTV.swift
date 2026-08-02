//
//  FocusStepperTV.swift
//  Karamock
//
//  Created by A422GQ on 02/08/2026.
//

import SwiftUI

struct FocusStepperTV: View {
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    var decrementDisabled = false
    var incrementDisabled = false
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: onDecrement) {
                Image(systemName: "minus.circle.fill")
            }
            .disabled(decrementDisabled)
            .accessibilityLabel("Diminuer")
            
            Button(action: onIncrement) {
                Image(systemName: "plus.circle.fill")
            }
            .disabled(incrementDisabled)
            .accessibilityLabel("Augmenter")
        }
        .font(.title2)
        .buttonStyle(.plain)
    }
}
