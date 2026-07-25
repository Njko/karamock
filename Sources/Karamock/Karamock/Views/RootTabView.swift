//
//  RootTabView.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var player = PlayerState()
    @Entry var downloadedSongsRepository: DownloadedSongsRepository = InMemoryDownloadedSongsRepository()
}

struct RootTabView: View {
    @State var player = PlayerState()
    @State var downloadedSongsRepository = InMemoryDownloadedSongsRepository()
    
    var body: some View {
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
        .environment(\.player, player)
        .environment(\.downloadedSongsRepository, downloadedSongsRepository)
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
    }
}
