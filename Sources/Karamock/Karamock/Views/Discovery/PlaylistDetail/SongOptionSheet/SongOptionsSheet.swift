//
//  SongSheet.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import SwiftUI
import FactoryKit

struct SongOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let song: Song
    
    @State private var viewModel: SongOptionsViewModel?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SongHeader(song: song)
                
                if let viewModel {
                    optionsContent(for: viewModel)
                }
                
                Button("Ajouter à la file d'attente") { }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .frame(maxWidth: .infinity)
                
                Button("Jouer maintenant") {
                    viewModel?.playNow()
                    dismiss()
                }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .onDisappear {
            viewModel?.downloadViewModel?.cancelDownload()
        }
        .task {
            if viewModel == nil {
                viewModel = Container.shared.songOptionsViewModel(song)
            }
        }
    }
    
    @ViewBuilder
    private func optionsContent(for viewModel: SongOptionsViewModel) -> some View {
        if let downloadViewModel = viewModel.downloadViewModel {
            DownloadButton(
                state: downloadViewModel.state,
                startDownload: downloadViewModel.startDownload
            )
        }
        
        SongOptionsForm(viewModel: viewModel)
    }
}
