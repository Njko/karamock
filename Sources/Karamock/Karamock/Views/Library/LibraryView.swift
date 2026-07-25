//
//  LibraryView.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI
import FactoryKit

struct LibraryView: View {
    @Injected(\.fetchDownloadedSongs) private var fetchDownloadedSongs
    @State private var viewModel: LibraryViewModel?
    @State private var selectedSong: Song?
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel, !viewModel.songs.isEmpty {
                    List(viewModel.songs) { song in
                        Button {
                            selectedSong = song
                        } label: {
                            SongRow(song: song)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView(
                        "Aucune chanson téléchargée",
                        systemImage: "arrow.down.circle",
                        description: Text("Télécharge une chanson depuis sa fiche pour la retrouver ici.")
                    )
                }
            }
            .navigationTitle("Bibliothèque")
        }
        .task {
            if viewModel == nil {
                viewModel = LibraryViewModel(fetchDownloadedSongs: fetchDownloadedSongs)
            }
            await viewModel?.refresh()
        }
        .refreshable {
            await viewModel?.refresh()
        }
        .sheet(item: $selectedSong) { song in
            SongOptionsSheet(song: song)
        }
    }
}
