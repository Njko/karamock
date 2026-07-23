//
//  PlaylistCoverHeader.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import SwiftUI

struct PlaylistCoverHeader: View {
    let playlist: Playlist
    
    var body: some View {
        LinearGradient(colors: playlist.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(height: 220)
            .overlay {
                Text(playlist.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
    }
}
