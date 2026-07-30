//
//  LyricsFetching.swift
//  Karamock
//
//  Created by A422GQ on 30/07/2026.
//

nonisolated protocol LyricsFetching: Sendable {
    func fetchLyrics(artist: String, title: String) async throws(LyricsError) -> String
}
