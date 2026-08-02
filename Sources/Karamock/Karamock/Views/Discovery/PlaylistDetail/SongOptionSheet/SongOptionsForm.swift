//
//  SongOptionsForm.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//
import SwiftUI

struct SongOptionsForm: View {
    @Bindable var viewModel: SongOptionsViewModel
#if os(iOS)
    private let spacing: CGFloat = 12
#else
    private let spacing: CGFloat = 24
#endif
    
    var body: some View {
        VStack(spacing: spacing) {
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
            #else
                .textFieldStyle(.automatic)
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
            #else
            FocusStepperTV(
                onDecrement: { viewModel.pitch = max(-12, viewModel.pitch - 1) },
                onIncrement: { viewModel.pitch = min(12, viewModel.pitch + 1)},
                decrementDisabled: viewModel.pitch <= -12,
                incrementDisabled: viewModel.pitch >= 12
            )
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
            #else
            FocusStepperTV(
                onDecrement: { viewModel.tempo = max(-50, viewModel.tempo - 1) },
                onIncrement: { viewModel.tempo = min(50, viewModel.tempo + 1)},
                decrementDisabled: viewModel.tempo <= -50,
                incrementDisabled: viewModel.tempo >= 50
            )
            #endif
        }
    }
}
