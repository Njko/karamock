//
//  MiniPlayerBar.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import SwiftUI

struct MiniPlayerBar: View {
    
    @Environment(\.player) var player
    
    let song: Song
    
    var body: some View {
        HStack(spacing:12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).font(.subheadline.bold())
                Text(song.artist).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                player.isPlaying.toggle()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            player.isExpanded = true
        }
    }
}
