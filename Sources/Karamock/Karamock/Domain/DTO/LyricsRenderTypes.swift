//
//  LyricsRenderTypes.swift
//  Karamock
//
//  Created by A422GQ on 10/08/2026.
//

import Foundation

nonisolated struct LyricsLinePayload: Sendable {
    let time: Double
    let text: String
}

nonisolated struct RenderedFrame: Sendable {
    let rgba: Data
    let width: Int
    let height: Int
    let bytesPerRow: Int
}
