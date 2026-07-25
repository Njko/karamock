//
//  DownloadState.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

enum DownloadState : Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed
}
