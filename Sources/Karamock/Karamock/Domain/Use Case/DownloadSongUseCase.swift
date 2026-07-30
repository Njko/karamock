//
//  DownloadDongUseCase.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

struct DownloadSongUseCase: Sendable {
    let service: SongDownloading
    let repository: DownloadedSongsRepository
    
    nonisolated init(
        service: SongDownloading,
        repository: DownloadedSongsRepository
    ) {
        self.service = service
        self.repository = repository
    }
    
    func callAsFunction(_ song: Song) -> AsyncStream<Double> {
        AsyncStream { continuation in
            let task = Task {
                for await progress in service.download(song) {
                    guard !Task.isCancelled else { break }
                    continuation.yield(progress)
                }
                if !Task.isCancelled {
                    await repository.add(song)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
