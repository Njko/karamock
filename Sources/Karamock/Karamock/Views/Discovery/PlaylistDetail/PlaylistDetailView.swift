//
//  PlaylistDetailView.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import SwiftUI

struct PlaylistDetailView: View {
    
    let playlist : Playlist
    @State private var selectedSong: Song?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PlaylistCoverHeader(playlist: playlist)
                
                ForEach(playlist.songs) { song in
                    Button {
                        selectedSong = song
                    } label: {
                        SongRow(song: song)
                    }
                    .buttonStyle(.plain)
                }
            }
            .ignoresSafeArea(edges: .top)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle(playlist.title)
            .sheet(item: $selectedSong) { song in
                SongOptionsSheet(song: song)
            }
        }
    }
}
