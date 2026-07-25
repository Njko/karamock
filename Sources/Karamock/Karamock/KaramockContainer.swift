//
//  KaramockContainer.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

import FactoryKit

extension Container {
    var player: Factory<PlayerState> {
        self { PlayerState() }
            .singleton
    }
    
    var downloadedSongsRepository: Factory<DownloadedSongsRepository> {
        self { InMemoryDownloadedSongsRepository() }
            .singleton
    }
    
    var downloadSong: Factory<DownloadSongUseCase> {
        self { DownloadSongUseCase(repository: self.downloadedSongsRepository()) }
    }
    
    var fetchDownloadedSongs: Factory<FetchDownloadedSongsUseCase> {
        self { FetchDownloadedSongsUseCase(repository: self.downloadedSongsRepository()) }
    }
}
