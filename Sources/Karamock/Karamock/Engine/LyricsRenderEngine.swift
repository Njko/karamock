//
//  LyricsRenderEngine.swift
//  Karamock
//
//  Created by A422GQ on 10/08/2026.
//

import Foundation
import CxxStdlib

actor LyricsRenderEngine {
    private var font = karamock.Font()
    private var fontLoaded = false
    private var store = karamock.LyricsStore()
    private var renderer = karamock.TextRenderer()
    private var page = karamock.LyricsPage()
    private var buffer = karamock.PixelBuffer()
    
    func loadFontIfNeeded(_ fontData: Data) {
        guard !fontLoaded else { return }
        fontLoaded = fontData.withUnsafeBytes { raw in
            guard let p = raw.bindMemory(to: UInt8.self).baseAddress else { return false }
            return font.loadFromMemory(p, raw.count)
        }
    }
    
    func setLyrics(_ lines: [LyricsLinePayload]) {
        store.clear()
        store.reserve(lines.count)
        for line in lines {
            store.addLine(line.time, std.string(line.text))
        }
    }
    
    // Rendu d'une frame — s'exécute hors MainActor, buffer réutilisé.
    func frame(at time: Double, pixelWidth: Int, pixelHeight: Int) -> RenderedFrame? {
        guard fontLoaded, pixelWidth > 0, pixelHeight > 0 else { return nil }

        buffer.resize(Int32(pixelWidth), Int32(pixelHeight))
        buffer.fill(20, 20, 30)
        page.render(&buffer, font, &renderer, store, time)

        // Copie via un unique appel C++ : aucun pointeur ne sort du buffer C++.
        let byteCount = buffer.sizeInBytes()
        guard byteCount > 0 else { return nil }
        var rgba = Data(count: byteCount)
        rgba.withUnsafeMutableBytes { raw in
            if let dst = raw.bindMemory(to: UInt8.self).baseAddress {
                buffer.copyPixels(dst, byteCount)
            }
        }
        return RenderedFrame(
            rgba: rgba,
            width: Int(buffer.width()),
            height: Int(buffer.height()),
            bytesPerRow: Int(buffer.bytesPerRow())
        )
    }
}
