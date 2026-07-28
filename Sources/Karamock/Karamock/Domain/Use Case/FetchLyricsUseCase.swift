//
//  FetchLyricsUseCase.swift
//  Karamock
//
//  Created by A422GQ on 28/07/2026.
//

struct FetchLyricsUseCase: Sendable {
    let repository : LyricsRepository
    
    nonisolated init(repository: LyricsRepository) {
        self.repository = repository
    }
    
    func callAsFunction(for song: Song) async throws(LyricsError) -> [LyricsLine] {
        try await repository.lyrics(for: song)
    }
}
