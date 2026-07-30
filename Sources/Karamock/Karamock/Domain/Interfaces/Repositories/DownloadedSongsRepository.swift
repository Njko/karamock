//
//  DownloadedSongsRepository.swift
//  Karamock
//
//  Created by A422GQ on 30/07/2026.
//

nonisolated protocol DownloadedSongsRepository : Sendable {
    func songs() async -> [Song]
    func add(_ song: Song) async
}
