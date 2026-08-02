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
        #if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: player.currentSong != nil && !player.isExpanded) {
            if let song = player.currentSong, !player.isExpanded {
                MiniPlayerBar(song: song)
            }
        }
        #else
        .overlay(alignment: .bottom) {
            if let song = player.currentSong, !player.isExpanded {
                MiniPlayerBarTV(song: song)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
            }
        }
        #endif
        .fullScreenCover(isPresented: $player.isExpanded) {
            if let song = player.currentSong {
                FullScreenPlayerView(song: song)
            }
        }
    }
}
