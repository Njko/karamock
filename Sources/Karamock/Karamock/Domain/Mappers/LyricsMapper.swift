//
//  LyricsMapper.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//

import Foundation

nonisolated enum LyricsMapper {
    static func map(rawText: String, duration: TimeInterval) -> [LyricsLine] {
        let lines = rawText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard !lines.isEmpty else { return [] }
        
        let interval = duration / Double(lines.count)
        return lines.enumerated().map { index, text in
            LyricsLine(time: Double(index) * interval, text: text)
        }
    }
}
