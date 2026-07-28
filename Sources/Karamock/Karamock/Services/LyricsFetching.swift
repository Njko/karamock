//
//  LyricsFetching.swift
//  Karamock
//
//  Created by A422GQ on 28/07/2026.
//

import Foundation
import os

protocol LyricsFetching: Sendable {
    func fetchLyrics(artist: String, title: String) async throws(LyricsError) -> String
}

private let lyricsFetcherLogger = Logger(subsystem: "fr.nicolaslinard.karamock", category: "Lyrics")

struct URLSessionLyricsFetching: LyricsFetching {
    func fetchLyrics(artist: String, title: String) async throws(LyricsError) -> String {
        guard let url = lyricsURL(artist: artist, title: title) else {
            throw .invalidURL
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            lyricsFetcherLogger.error("Echec reseau lyrics.ovh : \(error)")
            throw .network
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw .malformedResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw .notFound
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            lyricsFetcherLogger.error("Statut HTTP inattendu de lyrics.ovh: \(httpResponse)")
            throw .network
        }
        
        do {
            return try JSONDecoder().decode(LyricsResponse.self, from: data).lyrics
        } catch {
            lyricsFetcherLogger.error("Reponse lyrics.ovh non decodable: \(error)")
            throw .malformedResponse
        }
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
