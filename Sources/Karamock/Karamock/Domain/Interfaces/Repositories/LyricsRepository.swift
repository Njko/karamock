//
//  LyricsRepository.swift
//  Karamock
//
//  Created by A422GQ on 30/07/2026.
//

nonisolated protocol LyricsRepository: Sendable {
    func lyrics(for song: Song) async throws(LyricsError) -> [LyricsLine]
}
