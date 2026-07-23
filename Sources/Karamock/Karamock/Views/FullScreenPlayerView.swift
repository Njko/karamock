//
//  FullScreenPlayerView.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import SwiftUI
import Combine

struct FullScreenPlayerView: View {
    @Environment(\.player) private var player
    @Environment(\.dismiss) private var dismiss
    
    let song: Song
    
    @State private var progress: TimeInterval = 0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            LyricsView(lyrics: mockLyrics, currentTime: progress)
                .frame(height:160)
            
            VStack(spacing: 4) {
                Text(song.title).font(.title2.bold())
                Text(song.artist).foregroundStyle(.secondary)
            }
            
            VStack(spacing:8) {
                Slider(value: $progress, in: 0...song.durationInSeconds)
                HStack {
                    Text("0:00")
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
        }
        .padding()
        .onReceive(timer) { _ in
            guard player.isPlaying, progress < song.durationInSeconds else { return }
            progress += 0.5
        }
    }
}

#Preview {
    FullScreenPlayerView(song: Song(title: "Year of the cat", artist: "Cat Stevens", year: 1986, duration: "3:33", key: "A"))
        .environment(PlayerState())
}
