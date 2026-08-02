//
//  FullScreenPlayerView.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import FactoryKit
import SwiftUI
import Combine

struct FullScreenPlayerView: View {
    let song: Song
    
    @Injected(\.player) private var player
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var playButtonSize: CGFloat = 64
    @State private var viewModel: FullScreenPlayerViewModel?
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
            .accessibilityLabel("Fermer")
            
            LyricsView(lyrics: viewModel?.lyrics ?? placeholderLyrics, currentTime: progress)
                .frame(height:160)
            
            VStack(spacing: 4) {
                Text(song.title).font(.title2.bold())
                Text(song.artist).foregroundStyle(.secondary)
            }
            
            VStack(spacing:8) {
                #if os(iOS)
                Slider(value: $progress, in: 0...song.durationInSeconds)
                #else
                FocusStepperTV(
                    onDecrement: { progress = max(0, progress - 10) },
                    onIncrement: { progress = min(song.durationInSeconds, progress + 10)},
                    decrementDisabled: progress <= 0,
                    incrementDisabled: progress >= song.durationInSeconds
                )
                #endif
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
                .accessibilityLabel("Piste précédente")
                
                Button {
                    player.isPlaying.toggle()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: playButtonSize))
                }
                .accessibilityLabel(player.isPlaying ? "Mettre en pause" : "Lire")
                
                Button { } label: {
                    Image(systemName: "forward.fill").font(.title)
                }
                .accessibilityLabel("Piste suivante")
            }
            
            Spacer()
        }
        .padding()
        .onReceive(timer) { _ in
            guard player.isPlaying, progress < song.durationInSeconds else { return }
            progress += 0.5
        }
        .task(id: song.id) {
            let viewModel = Container.shared.fullScreenPlayerViewModel(song)
            self.viewModel = viewModel
            await viewModel.loadLyrics()
        }
    }
}

#Preview {
    FullScreenPlayerView(song: Song(title: "Year of the cat", artist: "Cat Stevens", year: 1986, duration: "3:33", key: "A"))
        .environment(PlayerState())
}
