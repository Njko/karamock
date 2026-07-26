//
//  PlaylistCard.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import SwiftUI

struct PlaylistCard: View {
    
    let playlist: Playlist
    
    var body: some View {
        LinearGradient(colors: playlist.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(width: 150, height: 150)
            .overlay(alignment: .bottomLeading) {
                Text(playlist.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .lineLimit(2)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityShowsLargeContentViewer {
                Text(playlist.title)
            }
    }
}
