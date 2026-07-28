//
//  KaramockContainer.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

import FactoryKit

extension Container {
    // Data
    var lyricsFetching: Factory<LyricsFetching> {
        self { URLSessionLyricsFetching() }
    }
    
    var lyricsRepository: Factory<LyricsRepository> {
        self { CachedLyricsRepository(service: self.lyricsFetching()) }
            .singleton
    }
    
    var downloadedSongsRepository: Factory<DownloadedSongsRepository> {
        self { SimpleDownloadedSongsRepository() }
            .singleton
    }

    // Domain
    var fetchLyrics: Factory<FetchLyricsUseCase> {
        self { FetchLyricsUseCase(repository: self.lyricsRepository()) }
    }
    
    var downloadSong: Factory<DownloadSongUseCase> {
        self { DownloadSongUseCase(service: MockSongDownloading(), repository: self.downloadedSongsRepository()) }
    }
    
    var fetchDownloadedSongs: Factory<FetchDownloadedSongsUseCase> {
        self { FetchDownloadedSongsUseCase(repository: self.downloadedSongsRepository()) }
    }
    
    // UI
    @MainActor
    var player: Factory<PlayerState> {
        self { PlayerState() }
            .singleton
    }
    
    @MainActor
    var fullScreenPlayerViewModel: ParameterFactory<Song, FullScreenPlayerViewModel> {
        self { song in FullScreenPlayerViewModel(song: song, fetchLyrics: self.fetchLyrics()) }
    }

    @MainActor
    var libraryViewModel : Factory<LibraryViewModel> {
        self { LibraryViewModel(fetchDownloadedSongs: self.fetchDownloadedSongs()) }
    }
    
    @MainActor
    var songDownloadViewModel: ParameterFactory<Song, SongDownloadViewModel> {
        self { song in SongDownloadViewModel(song:song, downloadSong: self.downloadSong()) }
    }
}
