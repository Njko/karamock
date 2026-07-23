//
//  RootTabView.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var player = PlayerState()
}

struct RootTabView: View {
    @State var player = PlayerState()
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
