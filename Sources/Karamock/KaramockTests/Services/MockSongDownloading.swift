//
//  MockSongDownloading.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//

@testable import Karamock

struct MockSongDownloading: SongDownloading {
    
    var shouldFail = false
    
    func download(_ song: Karamock.Song) -> AsyncThrowingStream<Double, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for step in 1...10 {
                        try await Task.sleep(for: .milliseconds(200))
                        if shouldFail, step == 5 {
                            throw SimulatedDownloadFailure()
                        }
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

private struct SimulatedDownloadFailure: Error {}
