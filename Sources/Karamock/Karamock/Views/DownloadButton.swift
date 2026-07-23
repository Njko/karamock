//
//  DownloadButton.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import SwiftUI

struct DownloadButton : View {
    let viewModel : SongDownloadViewModel
    
    var body: some View {
        switch viewModel.state {
        case .notDownloaded:
            Button("Télécharger", systemImage: "arrow.down.circle") {
                viewModel.startDownload()
            }
            
        case .downloading(let progress):
            HStack {
                ProgressView(value: progress)
                Text("\(Int(progress * 100)) %")
                    .font(.caption)
                    .monospacedDigit()
            }
            
        case .downloaded:
            Label("Téléchargé", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Button("Réessayer", systemImage: "exclamationmark.triangle") {
                viewModel.startDownload()
            }
        }
    }
}
