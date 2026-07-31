//
//  DownloadedSongsRepository.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

import Foundation
 
actor InMemoryDownloadedSongsRepository: DownloadedSongsRepository {
     private var storage: [Song] = []
    
    func songs() async -> [Song] {
        storage
    }
    
    init() {}
    
    func add(_ song: Song) async {
        guard !storage.contains(song) else { return }
        storage.append(song)
    }
}
