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
    
    func callAsFunction(_ song: Song) -> AsyncThrowingStream<Double, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await progress in service.download(song) {
                        guard !Task.isCancelled else { break }
                        continuation.yield(progress)
                    }
                    guard !Task.isCancelled else { return }
                    await repository.add(song)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
