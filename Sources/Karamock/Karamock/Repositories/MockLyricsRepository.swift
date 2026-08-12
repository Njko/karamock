//
//  MockLyricsRepository.swift
//  Karamock
//
//  Created by A422GQ on 12/08/2026.
//

actor MockLyricsRepository: LyricsRepository {
    func lyrics(for song: Song) async throws(LyricsError) -> [LyricsLine] {
        return await placeholderLyrics
    }
}
