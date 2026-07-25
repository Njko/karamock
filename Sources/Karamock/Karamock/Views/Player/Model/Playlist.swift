//
//  Untitled.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import Foundation
import SwiftUI

struct Playlist: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let gradientColors: [Color]
    let songs: [Song]
}

let mockPlaylist: [Playlist] = [
    Playlist(title: "Best Of", gradientColors: [.red, .orange], songs: [
        Song(title: "You Give Love A Bad Name", artist: "Bon Jovi", year: 1986, duration: "3:35", key: "Cm"),
        Song(title: "Sweet Child O' Mine", artist: "Guns N' Roses", year: 1987, duration: "5:56", key: "Dm"),
        Song(title: "Nothing Else Matters", artist: "Mettalica", year: 1991, duration: "6:28", key: "Em"),
        Song(title: "Livin' on a Prayer", artist: "Bon Jovi", year: 1986, duration: "4:09", key: "Dm"),
        Song(title: "Gimme Three Steps", artist: "Lynyrd Skynyrd", year: 1973, duration: "4:31", key: "A")
    ]),
    Playlist(title: "Années 2000\nen France ", gradientColors: [.blue, .green], songs: [
        Song(title: "You Give Love A Bad Name", artist: "Bon Jovi", year: 1986, duration: "3:35", key: "Cm"),
        Song(title: "Sweet Child O' Mine", artist: "Guns N' Roses", year: 1987, duration: "5:56", key: "Dm"),
        Song(title: "Nothing Else Matters", artist: "Mettalica", year: 1991, duration: "6:28", key: "Em"),
        Song(title: "Livin' on a Prayer", artist: "Bon Jovi", year: 1986, duration: "4:09", key: "Dm"),
        Song(title: "Gimme Three Steps", artist: "Lynyrd Skynyrd", year: 1973, duration: "4:31", key: "A")
    ]),
    Playlist(title: "Karaoké\nClassics", gradientColors: [.yellow, .purple], songs: [
        Song(title: "You Give Love A Bad Name", artist: "Bon Jovi", year: 1986, duration: "3:35", key: "Cm"),
        Song(title: "Sweet Child O' Mine", artist: "Guns N' Roses", year: 1987, duration: "5:56", key: "Dm"),
        Song(title: "Nothing Else Matters", artist: "Mettalica", year: 1991, duration: "6:28", key: "Em"),
        Song(title: "Livin' on a Prayer", artist: "Bon Jovi", year: 1986, duration: "4:09", key: "Dm"),
        Song(title: "Gimme Three Steps", artist: "Lynyrd Skynyrd", year: 1973, duration: "4:31", key: "A")
    ])
]
