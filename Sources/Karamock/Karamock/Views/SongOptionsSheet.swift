//
//  SongSheet.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import SwiftUI

struct SongOptionsSheet: View {
    @Environment(\.player) private var player
    @Environment(\.dismiss) private var dismiss
    
    let song: Song
    
    @State private var downloadViewModel: SongDownloadViewModel?
    
    @State private var mode: KaraokeMode = .karaoke
    @State private var singerName: String = ""
    @State private var adjustVolumes = false
    @State private var pitch: Double = 0
    @State private var tempo: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SongHeader(song: song)
                
                if let downloadViewModel {
                    DownloadButton(viewModel: downloadViewModel)
                }
                
                VStack(spacing: 12) {
                    ForEach(KaraokeMode.allCases) { option in
                        ModeCard(option: option, isSelected: mode == option) {
                            mode = option
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chanté par").font(.headline)
                    TextField("Chanteur", text: $singerName)
                        .textFieldStyle(.roundedBorder)
                    
                }
                
                Toggle("Régler les volumes", isOn: $adjustVolumes)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Tonalité")
                        Spacer()
                        Text("\(Int(pitch))")
                    }
                    Slider(value: $pitch, in: -12...12, step: 1)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Tempo")
                        Spacer()
                        Text("\(Int(tempo))")
                    }
                    Slider(value: $tempo, in: -50...50, step: 5)
                }
                
                Button("Ajouter à la file d'attente") { }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .frame(maxWidth: .infinity)
                
                Button("Jouer maintenant") {
                    player.currentSong = song
                    player.isPlaying = true
                    player.isExpanded = true
                    dismiss()
                }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .task {
            if downloadViewModel == nil {
                downloadViewModel = SongDownloadViewModel(song: song)
            }
        }
    }
}
