//
//  SongRow.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import SwiftUI

struct SongRow: View {
    
    let song: Song
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
            #if os(iOS)
                .frame(width: 50, height: 50)
            #else
                .frame(width: 80, height: 80)
            #endif
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        #if os(iOS)
        .padding(.vertical, 4)
        #else
        .padding(.vertical, 16)
        #endif
    }
}
