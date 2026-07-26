//
//  DownloadDongUseCase.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

struct DownloadSongUseCase: Sendable {
    let service: SongDownloading
    let repository: DownloadedSongsRepository
    
    init(
        service: SongDownloading,
        repository: DownloadedSongsRepository
    ) {
        self.service = service
        self.repository = repository
    }
    
    func callAsFunction(_ song: Song) -> AsyncStream<Double> {
        AsyncStream { continuation in
            Task {
                for await progress in service.download(song) {
                    continuation.yield(progress)
                }
                await repository.add(song)
                continuation.finish()
            }
        }
    }
}
