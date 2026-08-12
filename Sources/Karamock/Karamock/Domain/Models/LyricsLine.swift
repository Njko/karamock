//
//  LyricsLine.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import Foundation

struct LyricsLine : Identifiable, Hashable {
    let id = UUID()
    let time : TimeInterval
    let text : String
}

let placeholderLyrics: [LyricsLine] = [
    LyricsLine(time: 0, text: "Premiere ligne des paroles simulees"),
    LyricsLine(time: 4, text: "Chaque ligne a son propre horodatage"),
    LyricsLine(time: 8, text: "Le refrain arrive dans quelques secondes"),
    LyricsLine(time: 12, text: "On surligne la ligne courante en la comparant au temps"),
    LyricsLine(time: 16, text: "Et on fait defiler la vue jusqu'a elle"),
    LyricsLine(time: 20, text: "Sans jamais stocker \"quelle ligne est active\" a part"),
]
