//
//  MiniPlayerBarTV.swift
//  Karamock
//
//  Created by A422GQ on 02/08/2026.
//

import SwiftUI
import FactoryKit

struct MiniPlayerBarTV: View {
    @Injected(\.player) private var player
    let song: Song
    
    var body: some View {
        Button {
            player.isExpanded = true
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title).font(.headline)
                    Text(song.artist).font(.subheadline).foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .padding(20)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(song.title), \(song.artist), \(player.isPlaying ? "en lecture" : "en pause")")
        .accessibilityHint("Ouvrir le lecteur plein écran")
    }
}
