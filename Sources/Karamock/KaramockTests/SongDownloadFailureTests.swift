//
//  SongDownloadFailureTests.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//

import Testing
import FactoryKit
import FactoryTesting
@testable import Karamock

@Suite(.container)
struct SongDownloadFailureTests {
    @Test
    @MainActor
    func failedDownloadTransitionsToFailedState() async throws {
        let song = Song(title: "Kasmir", artist: "Led Zeppelin", year: 1975, duration: "3:05", key: "E")
        Container.shared.downloadedSongsRepository { MockDownloadedSongsRepository() }
        Container.shared.songDownloading { MockSongDownloading(shouldFail: true) }
        
        let viewModel = Container.shared.songDownloadViewModel(song)
        viewModel.startDownload()
        
        // MockSongDownloading avec le paramètre shouldFail déclenche un échec à la 5e étape
        try await Task.sleep(for: .milliseconds(1250))
        
        #expect(viewModel.state == .failed)
    }
}
