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
    private let downloadSong: DownloadSongUseCase
    
    private var downloadTask: Task<Void, Never>?
    
    init(
        song: Song,
        downloadSong: DownloadSongUseCase
    ) {
        self.song = song
        self.downloadSong = downloadSong
    }
    
    func startDownload() {
        guard state == .notDownloaded || state == .failed else { return }
        state = .downloading(progress: 0)
        downloadTask = Task {
            for await progress in downloadSong(song) {
                guard !Task.isCancelled else { return }
                state = .downloading(progress: progress)
            }
            guard !Task.isCancelled else { return }
            state = .downloaded
            downloadTask = nil
        }
    }
    
    func cancelDownload() {
        guard case .downloading = state else { return }
        downloadTask?.cancel()
        downloadTask = nil
        state = .notDownloaded
    }
}
