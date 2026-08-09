//
//  DiscoveryView.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI

struct DiscoveryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PlaylistSection(playlists: mockPlaylist)
                }
                .padding(.top)
            }
            .navigationTitle("Découvrir")
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist:playlist)
            }
        }
    }
}
