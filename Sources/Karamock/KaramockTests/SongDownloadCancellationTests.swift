//
//  SongDownloadCancellationTests.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//

import Testing
import FactoryKit
import FactoryTesting
@testable import Karamock

@Suite(.container)
struct SongDownloadCancellationTests {
    
    @Test
    @MainActor
    func cancellingMidDownloadNeverPersistsTheSong() async throws {
        let song = Song(title: "Kasmir", artist: "Led Zeppelin", year: 1975, duration: "3:05", key: "E")
        let repository = MockDownloadedSongsRepository()
        Container.shared.downloadedSongsRepository { repository }
        Container.shared.songDownloading { MockSongDownloading()}
        
        let viewModel = Container.shared.songDownloadViewModel(song)
        viewModel.startDownload()
        
        try await Task.sleep(for: .milliseconds(250))
        viewModel.cancelDownload()
        
        try await Task.sleep(for: .milliseconds(2500))
        
        #expect(await repository.songs().isEmpty)
    }
}
