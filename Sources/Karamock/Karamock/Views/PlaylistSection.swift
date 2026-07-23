//
//  PlaylistSection.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI

struct PlaylistSection: View {
    let playlists: [Playlist]
    
    var body: some View {
        VStack(alignment: .leading) {
            Label("Playlist", systemImage: "music.note")
                .font(.title3.bold())
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(playlists) { playlist in
                        NavigationLink(value:playlist) {
                            PlaylistCard(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    PlaylistSection(playlists: mockPlaylist)
}
