//
//  SongDownloading.swift
//  Karamock
//
//  Created by A422GQ on 30/07/2026.
//

nonisolated protocol SongDownloading : Sendable {
    func download(_ song: Song) -> AsyncStream<Double>
}
