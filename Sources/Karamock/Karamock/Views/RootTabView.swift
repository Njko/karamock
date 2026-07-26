//
//  RootTabView.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI
import FactoryKit

struct RootTabView: View {
    @Injected(\.player) private var player
    
    var body: some View {
        @Bindable var player = player
        
        TabView {
            DiscoveryView()
                .tabItem {
                    Label("Découvrir", systemImage: "book.closed.fill")
                }
            LibraryView()
                .tabItem {
                    Label("Bibliothèque", systemImage: "music.note.list")
                }
        }
        .overlay(alignment: .bottom) {
            if let song = player.currentSong, !player.isExpanded {
                MiniPlayerBar(song: song)
                    .padding(.bottom, 49)
            }
        }
        .fullScreenCover(isPresented: $player.isExpanded) {
            if let song = player.currentSong {
                FullScreenPlayerView(song: song)
            }
        }
        .onAppear {
            Task {
                try await Task.sleep(for: .seconds(4))
                withAnimation {
                    player.currentSong = .init(title: "hello wol", artist: "artis", year: 2999, duration: "3:35", key: "C")
                    player.isPlaying.toggle()
                }
            }
        }
    }
}
