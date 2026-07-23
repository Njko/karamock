//
//  Song.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

import Foundation

struct Song: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let year: Int
    let duration: String
    let key: String
}
