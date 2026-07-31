//
//  SongOptionsViewModel.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//

import Foundation

@MainActor
@Observable

final class SongOptionsViewModel {
    private let song: Song
    private let player: PlayerState
    
    var downloadViewModel: SongDownloadViewModel?
    
    var mode: KaraokeMode = .karaoke
    var singerName: String = ""
    var adjustVolumes = false
    var pitch: Double = 0
    var tempo: Double = 0
    
    init(song: Song, player: PlayerState, downloadViewModel: SongDownloadViewModel? = nil) {
        self.song = song
        self.player = player
        self.downloadViewModel = downloadViewModel
    }
    
    func playNow() {
        player.currentSong = song
        player.isPlaying = true
        player.isExpanded = true
    }
}
