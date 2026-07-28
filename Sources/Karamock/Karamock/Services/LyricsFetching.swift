//
//  LyricsFetching.swift
//  Karamock
//
//  Created by A422GQ on 28/07/2026.
//

import Foundation

protocol LyricsFetching: Sendable {
    func fetchLyrics(artist: String, title: String) async throws -> String
}

struct URLSessionLyricsFetching: LyricsFetching {
    func fetchLyrics(artist: String, title: String) async throws -> String {
        guard let url = lyricsURL(artist: artist, title: title) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(LyricsResponse.self, from: data)
        return response.lyrics
    }
}

private func lyricsURL(artist: String, title: String) -> URL? {
    guard let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    else {
        return nil
    }
    
    return URL(string: "https://api.lyrics.ovh/v1/\(encodedArtist)/\(encodedTitle)" )
}

private struct LyricsResponse: Decodable {
    let lyrics: String
}
