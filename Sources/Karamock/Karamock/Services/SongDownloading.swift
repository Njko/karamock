//
//  SongDownloading.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

protocol SongDownloading : Sendable {
    func download(_ song: Song) -> AsyncStream<Double>
}

struct MockSongDownloading: SongDownloading {
    func download(_ song: Song) -> AsyncStream<Double> {
        AsyncStream { continuation in
            Task {
                for step in 1...10 {
                    try? await Task.sleep(for: .milliseconds(200))
                    continuation.yield(Double(step) / 10)
                }
                continuation.finish()
            }
        }
    }
}
