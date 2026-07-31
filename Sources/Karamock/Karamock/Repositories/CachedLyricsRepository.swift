//
//  CachedLyricsRepository.swift
//  Karamock
//
//  Created by A422GQ on 28/07/2026.
//

import Foundation

actor CachedLyricsRepository: LyricsRepository {
    private let service: LyricsFetching
    private var cache: [Song.ID: [LyricsLine]] = [:]
    
    init(service: LyricsFetching) {
        self.service = service
    }
    
    func lyrics(for song: Song) async throws(LyricsError) -> [LyricsLine] {
        if let cached = await cache[song.id] {
            return cached
        }
        
        let rawText = try await service.fetchLyrics(artist: song.artist, title: song.title)
        
        let result = LyricsMapper.map(rawText: rawText, duration: song.durationInSeconds)
        
        await cache[song.id] = result
        return result
    }
}
