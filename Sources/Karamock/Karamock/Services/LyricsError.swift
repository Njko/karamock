//
//  LyricsError.swift
//  Karamock
//
//  Created by A422GQ on 28/07/2026.
//

enum LyricsError: Error, Sendable {
    case invalidURL
    case notFound
    case network
    case malformedResponse
}
