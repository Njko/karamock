//
//  SongDownloadViewModel.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import Foundation

@MainActor
@Observable
final class SongDownloadViewModel {
    private(set) var state: DownloadState = .notDownloaded
    
    private let song : Song
    private let service: SongDownloading
    private let markSongAsDownloaded: DownloadSongUseCase
    
    init(
        song: Song,
        service: SongDownloading = MockSongDownloading(),
        markSongAsDownloaded: DownloadSongUseCase
    ) {
        self.song = song
        self.service = service
        self.markSongAsDownloaded = markSongAsDownloaded
    }
    
    func startDownload() {
        guard state == .notDownloaded || state == .failed else { return }
        state = .downloading(progress: 0)
        Task {
            for await progress in service.download(song) {
                state = .downloading(progress: progress)
            }
            await markSongAsDownloaded(song)
            state = .downloaded
        }
    }
}
