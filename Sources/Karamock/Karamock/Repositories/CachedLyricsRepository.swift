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
        if let cached = cache[song.id] {
            return cached
        }
        
        let rawText = try await service.fetchLyrics(artist: song.artist, title: song.title)
        let lines = rawText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        
        guard !lines.isEmpty else { return [] }
        
        let interval = song.durationInSeconds/Double(lines.count)
        
        let result = lines.enumerated().map { index, text in
            LyricsLine(time: Double(index) * interval, text: text)
        }
        
        cache[song.id] = result
        return result
    }
}
