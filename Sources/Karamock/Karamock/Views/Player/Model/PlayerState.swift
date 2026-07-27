//
//  PlayerState.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import Foundation

@MainActor
@Observable
final class PlayerState {
    var currentSong: Song?
    var isPlaying = false
    var isExpanded = false
}
