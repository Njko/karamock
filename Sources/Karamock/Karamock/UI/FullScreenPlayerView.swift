//
//  FullScreenPlayerView.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import SwiftUI

struct FullScreenPlayerView: View {
    @Environment(\.player) private var player
    @Environment(\.dismiss) private var dismiss
    
    let song: Song
    
    var body: some View {
        VStack(spacing: 32) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
                .frame(width:260, height: 260)
            
            VStack(spacing: 4) {
                Text(song.title).font(.title2.bold())
                Text(song.artist).foregroundStyle(.secondary)
            }
            
            VStack(spacing:8) {
                Slider(value: .constant(0.35))
                HStack {
                    Text("1:15")
                    Spacer()
                    Text("-" + song.duration)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 48) {
                Button { } label: {
                    Image(systemName: "backward.fill").font(.title)
                }
                
                Button {
                    player.isPlaying.toggle()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                
                Button { } label: {
                    Image(systemName: "forward.fill").font(.title)
                }
            }
            
            Spacer()
        }.padding()
    }
}
