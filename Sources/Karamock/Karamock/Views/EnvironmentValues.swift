//
//  EnvironmentValues.swift
//  Karamock
//
//  Created by A422GQ on 25/07/2026.
//
import SwiftUI

extension EnvironmentValues {
    @Entry var player = PlayerState()
    @Entry var downloadedSongsRepository: DownloadedSongsRepository = InMemoryDownloadedSongsRepository()
}
