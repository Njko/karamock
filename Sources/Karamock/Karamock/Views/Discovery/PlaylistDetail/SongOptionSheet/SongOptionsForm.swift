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
                .textFieldStyle(.roundedBorder)
            
        }
        
        Toggle("Régler les volumes", isOn: $viewModel.adjustVolumes)
        
        VStack(alignment: .leading) {
            HStack {
                Text("Tonalité")
                Spacer()
                Text("\(Int(viewModel.pitch))")
            }
            Slider(value: $viewModel.pitch, in: -12...12, step: 1)
        }
        
        VStack(alignment: .leading) {
            HStack {
                Text("Tempo")
                Spacer()
                Text("\(Int(viewModel.tempo))")
            }
            Slider(value: $viewModel.tempo, in: -50...50, step: 5)
        }
    }
}
