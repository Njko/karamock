//
//  FetchDownloadedSongsUseCase.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//

struct FetchDownloadedSongsUseCase: Sendable {
    let repository: DownloadedSongsRepository
    
    init(repository: DownloadedSongsRepository) {
        self.repository = repository
    }
    
    func callAsFunction() async -> [Song] {
        await repository.songs()
    }
}
