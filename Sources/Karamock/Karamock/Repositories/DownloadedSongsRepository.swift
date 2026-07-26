//
//  DownloadedSongsRepository.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

import Foundation

protocol DownloadedSongsRepository : Sendable {
    func songs() async -> [Song]
    func add(_ song: Song) async
}

final class SimpleDownloadedSongsRepository: DownloadedSongsRepository {
    nonisolated(unsafe) private var storage: [Song] = []
    
    func songs() async -> [Song] {
        storage
    }
    
    func add(_ song: Song) async {
        guard !storage.contains(song) else { return }
        storage.append(song)
    }
}





