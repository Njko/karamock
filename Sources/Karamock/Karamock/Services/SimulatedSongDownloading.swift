//
//  SongDownloading.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

struct SimulatedSongDownloading: SongDownloading {
    
    func download(_ song: Song) -> AsyncThrowingStream<Double, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for step in 1...10 {
                        try await Task.sleep(for: .milliseconds(200))
                        continuation.yield(Double(step) / 10)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
