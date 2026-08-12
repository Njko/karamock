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
    @State private var clock = PlaybackClock()
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
            .padding([.horizontal, .top])
            
            TimelineView(.animation(minimumInterval: nil, paused: !player.isPlaying)) { _ in
                LyricsEngineView(
                    lyrics: viewModel?.lyrics ?? placeholderLyrics,
                    currentTime: min(clock.currentTime(), song.durationInSeconds)
                )
            }
            .frame(height: 160)
            VStack(spacing: 4) {
                Text(song.title).font(.title2.bold())
                Text(song.artist).foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing:8) {
                #if os(iOS)
                Slider(value: Binding(
                    get: { progress },
                    set: { newValue in
                        progress = newValue
                        clock.sync(to: newValue, running: player.isPlaying)
                    }
                ),in: 0...song.durationInSeconds)
                #else
                FocusStepperTV(
                    onDecrement: { progress = max(0, progress - 10); clock.sync(to: progress, running: player.isPlaying) },
                    onIncrement: { progress = min(song.durationInSeconds, progress + 10); clock.sync(to: progress, running: player.isPlaying) },
                    decrementDisabled: progress <= 0,
                    incrementDisabled: progress >= song.durationInSeconds
                )
                #endif
                HStack {
                    Text(formatTime(progress))
                    Spacer()
                    Text("-" + formatTime(song.durationInSeconds - progress))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
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
            .padding(.horizontal)
            
            Spacer()
        }
        #if os(tvOS)
        .onPlayPauseCommand { player.isPlaying.toggle() }
        #endif
        .onReceive(timer) { _ in
            guard player.isPlaying else { return }
            let time = clock.currentTime()
            if time >= song.durationInSeconds {
                progress = song.durationInSeconds
                clock.sync(to: song.durationInSeconds, running: false)
            } else {
                progress = time
            }
        }
        .onChange(of: player.isPlaying) { _, playing in
            clock.sync(to: progress, running: playing)
        }
        .task(id: song.id) {
            let viewModel = Container.shared.fullScreenPlayerViewModel(song)
            self.viewModel = viewModel
            clock.sync(to: progress, running: player.isPlaying)
            await viewModel.loadLyrics()
        }
    }
}

#Preview {
    Container.shared.fetchLyrics {
        .init(repository: MockLyricsRepository())
    }
    return FullScreenPlayerView(song: Song(title: "Year of the cat", artist: "Cat Stevens", year: 1986, duration: "3:33", key: "A"))
}
