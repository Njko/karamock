//
//  FullScreenPlayerViewModel.swift
//  Karamock
//
//  Created by A422GQ on 28/07/2026.
//

import Foundation

@MainActor
@Observable
final class FullScreenPlayerViewModel {
    private(set) var lyrics: [LyricsLine] = mockLyrics
    
    private let song: Song
    private let fetchLyrics: FetchLyricsUseCase
    
    init(song: Song, fetchLyrics: FetchLyricsUseCase) {
        self.song = song
        self.fetchLyrics = fetchLyrics
    }
    
    func loadLyrics() async {
        do throws(LyricsError){
            lyrics = try await fetchLyrics(for: song)
        } catch {
            switch error {
            case .notFound:
                lyrics = [LyricsLine(time: 0, text: "Paroles indisponibles pour cette chanson.")]
            case .network:
                lyrics = [LyricsLine(time: 0, text: "Connexion impossible. Réessayez")]
            case .invalidURL, .malformedResponse:
                lyrics = [LyricsLine(time: 0, text: "Paroles indisponibles pour le moment.")]
            }
        }
    }
}
