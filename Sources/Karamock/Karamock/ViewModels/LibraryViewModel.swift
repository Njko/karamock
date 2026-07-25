//
//  LibraryViewModel.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

import Foundation

@MainActor
@Observable
final class LibraryViewModel {
    private(set) var songs: [Song] = []
    
    private let fetchDownloadedSongs: FetchDownloadedSongsUseCase
    
    init(fetchDownloadedSongs: FetchDownloadedSongsUseCase) {
        self.fetchDownloadedSongs = fetchDownloadedSongs
    }
    
    func refresh() async {
        songs = await fetchDownloadedSongs()
    }
}
