//
//  DownloadDongUseCase.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

struct DownloadSongUseCase: Sendable {
    let repository: DownloadedSongsRepository
    
    func callAsFunction(_ song: Song) async {
        await repository.add(song)
    }
}
