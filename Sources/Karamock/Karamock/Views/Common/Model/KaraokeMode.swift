//
//  KaraokeMode.swift
//  Karamock
//
//  Created by A422GQ on 22/07/2026.
//

enum KaraokeMode: String, CaseIterable, Identifiable {
    case karaoke = "Karaoke"
    case battle = "Karaoke avec scoring des voix"
    
    var id: String { rawValue }
    var title: String { self == .karaoke ? "Karaoke" : "Battle" }
    var subtitle: String { rawValue }
    var systemImage: String { self == .karaoke ? "pencil.tip" : "figure.fencing" }
}
