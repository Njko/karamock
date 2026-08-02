//
//  SongOptionsForm.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//
import SwiftUI

struct SongOptionsForm: View {
    @Bindable var viewModel: SongOptionsViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(KaraokeMode.allCases) { option in
                ModeCard(option: option, isSelected: viewModel.mode == option) {
                    viewModel.mode = option
                }
            }
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Chanté par").font(.headline)
            TextField("Chanteur", text: $viewModel.singerName)
            #if os(iOS)
                .textFieldStyle(.roundedBorder)
            #endif
        }
        
        Toggle("Régler les volumes", isOn: $viewModel.adjustVolumes)
        
        VStack(alignment: .leading) {
            HStack {
                Text("Tonalité")
                Spacer()
                Text("\(Int(viewModel.pitch))")
            }
            #if os(iOS)
            Slider(value: $viewModel.pitch, in: -12...12, step: 1)
            #endif
        }
        
        VStack(alignment: .leading) {
            HStack {
                Text("Tempo")
                Spacer()
                Text("\(Int(viewModel.tempo))")
            }
            #if os(iOS)
            Slider(value: $viewModel.tempo, in: -50...50, step: 5)
            #endif
        }
    }
}
