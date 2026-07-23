//
//  SongHeader.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import SwiftUI

struct SongHeader: View {
    
    let song: Song
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title).font(.title3.bold())
                Text(song.artist).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label("\(song.year)", systemImage: "calendar")
                    Label(song.duration, systemImage: "clock")
                    Label(song.key, systemImage: "wrench.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
