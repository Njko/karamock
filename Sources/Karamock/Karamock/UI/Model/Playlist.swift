//
//  Untitled.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import Foundation
import SwiftUI

struct Playlist: Identifiable {
    let id = UUID()
    let title: String
    let gradientColors: [Color]
}

let mockPlaylist: [Playlist] = [
    Playlist(title: "Best Of", gradientColors: [.red, .orange]),
    Playlist(title: "Années 2000\nen France ", gradientColors: [.blue, .green]),
    Playlist(title: "Karaoké\nClassics", gradientColors: [.yellow, .purple])
]
