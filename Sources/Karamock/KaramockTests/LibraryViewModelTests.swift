//
//  LibraryViewModelTests.swift
//  Karamock
//
//  Created by A422GQ on 26/07/2026.
//

import Testing
import FactoryKit
import FactoryTesting
@testable import Karamock

@Suite(.container)
struct LibraryViewModelTests {
    
    @Test
    @MainActor
    func refreshLoadsDownloadedSongs() async {
        let song = Song(title: "Year of the Cat", artist: "Al Stewart", year: 1976, duration: "6:34", key: "Em")
        Container.shared.fetchDownloadedSongs {
            FetchDownloadedSongsUseCase(repository: MockDownloadedSongsRepository(songs: [song]))
        }
        
        let viewModel = Container.shared.libraryViewModel()
        await viewModel.refresh()
        
        #expect(viewModel.songs == [song])
    }
    
    @Test
    @MainActor
    func refreshWithNodowloadedSongsLeavesLibraryEmpty() async {
        Container.shared.fetchDownloadedSongs {
            FetchDownloadedSongsUseCase(repository: MockDownloadedSongsRepository())
        }
        
        let viewModel = Container.shared.libraryViewModel()
        await viewModel.refresh()
        
        #expect(viewModel.songs.isEmpty)
    }
}
