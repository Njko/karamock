//
//  ModeCard.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//
import SwiftUI

struct ModeCard : View {
    let option : KaraokeMode
    let isSelected : Bool
    let onSelect : () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: option.systemImage)
                VStack(alignment: .leading) {
                    Text(option.title).font(.headline)
                    Text(option.subtitle).font(.subheadline)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            }
            .padding()
            #if os(iOS)
            .background(isSelected ? Color.purple.opacity(0.15) : Color(.secondarySystemBackground))
            #endif
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ModeCard(option: .karaoke, isSelected: false, onSelect: {})
}
