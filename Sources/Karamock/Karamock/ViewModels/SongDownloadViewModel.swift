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
        Task {
            for await progress in downloadSong(song) {
                state = .downloading(progress: progress)
            }
            state = .downloaded
        }
    }
}
