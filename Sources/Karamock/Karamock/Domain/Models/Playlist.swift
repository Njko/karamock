//
//  Untitled.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import Foundation

struct Playlist: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let songs: [Song]
}
