//
//  MockDownloadedSongsRepository.swift
//  Karamock
//
//  Created by A422GQ on 26/07/2026.
//

@testable import Karamock

actor MockDownloadedSongsRepository: DownloadedSongsRepository {
    private var storage: [Song]
    
    init(songs: [Song] = []) {
        self.storage = songs
    }
    
    func songs() async -> [Song] {
        storage
    }
    
    func add(_ song: Song) async {
        storage.append(song)
    }
}
