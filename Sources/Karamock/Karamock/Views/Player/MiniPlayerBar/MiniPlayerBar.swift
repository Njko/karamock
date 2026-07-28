//
//  MiniPlayerBar.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import FactoryKit
import SwiftUI

struct MiniPlayerBar: View {
    
    @Injected(\.player) private var player
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    
    let song: Song
    
    var body: some View {
        Group {
            if placement == .inline {
                compactContent
            } else {
                expandedContent
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            player.isExpanded = true
        }
    }
    
    private var compactContent: some View {
        Button {
            player.isPlaying.toggle()
        } label: {
            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.title3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(player.isPlaying ? "Mettre en pause" : "Lire")
    }
    
    private var expandedContent: some View {
        HStack(spacing:12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).font(.subheadline.bold())
                Text(song.artist).font(.caption).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                player.isExpanded = true
            }
            
            Spacer()
            
            Button {
                player.isPlaying.toggle()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.isPlaying ? "Mettre en pause" : "Lire")
        }
        .padding(.horizontal, 16)
    }
}
