//
//  LyricsView.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import SwiftUI

struct LyricsView : View {
    
    let lyrics: [LyricsLine]
    let currentTime: TimeInterval
    
    private var currentLine: LyricsLine? {
        lyrics.last { $0.time <= currentTime }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lyrics) { line in
                        Text(line.text)
                            .font(line == currentLine ? .title3.bold() : .body)
                            .foregroundStyle(line == currentLine ? .primary : .secondary)
                            .id(line.id)
                        
                    }
                }
            }
            .onChange(of: currentLine) { _, newLine in
                guard let newLine else { return }
                withAnimation {
                    proxy.scrollTo(newLine.id, anchor: .center)
                }
            }
        }
    }
}
