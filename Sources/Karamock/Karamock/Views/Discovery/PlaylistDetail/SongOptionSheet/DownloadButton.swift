//
//  DownloadButton.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import SwiftUI

struct DownloadButton : View {
    let state : DownloadState
    let startDownload: () -> Void
    
    var body: some View {
        switch state {
        case .notDownloaded:
            Button("Télécharger", systemImage: "arrow.down.circle") {
                startDownload()
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
                startDownload()
            }
        }
    }
}
