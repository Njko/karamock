//
//  EngineProofView.swift
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

import CoreGraphics
import Foundation
import SwiftUI

struct EngineProofView: View {
    @Environment(\.displayScale) private var displayScale
    @State private var startDate = Date()
    @State private var fontData: Data?
    
    private let pointSize = CGSize(width: 320, height: 200)
    
    var body: some View {
        TimelineView(.periodic(from: startDate, by: 0.1)) { context in
            content(at: context.date)
                .frame(width: pointSize.width, height: pointSize.height)
        }
        .task {
            guard fontData == nil else { return }
            guard let fontURL = Bundle.main.url(forResource: "NotoSans-Regular", withExtension: "ttf") else { return }
            fontData = try? Data(contentsOf: fontURL)
        }
    }
    
    @ViewBuilder
    private func content(at date: Date) -> some View {
        if let fontData, let image = Self.render(pointSize: pointSize, scale: displayScale, fontData: fontData, currentTime: date.timeIntervalSince(startDate)) {
            Image(decorative: image, scale: displayScale)
                .interpolation(.none)
        } else {
            ProgressView()
        }
    }
    
    private static func render(pointSize: CGSize, scale: CGFloat, fontData: Data, currentTime: Double) -> CGImage? {
        let pixelWidth: Int = Int((pointSize.width * scale).rounded())
        let pixelHeight: Int = Int((pointSize.height * scale).rounded())
        
        var font = karamock.Font()
        guard loadFont(from: fontData, into: &font) else { return nil }
        
        var buffer = karamock.PixelBuffer()
        buffer.resize(Int32(pixelWidth), Int32(pixelHeight))
        buffer.fill(20, 20, 30)
        
        var lyricsStore = karamock.LyricsStore()
        let testLines: [(time: Double, text: String)] = [
            (0.0, "Premiere ligne, deja terminee"),
            (2.0, "Deuxieme ligne, celle qui joue maintenant"),
            (4.0, "Troisieme ligne, pas encore arrivee")
        ]
        lyricsStore.reserve(testLines.count)
        for line in testLines {
            lyricsStore.addLine(line.time, std.string(line.text))
        }
        
        var renderer = karamock.TextRenderer()
        let page = karamock.LyricsPage()
        page.render(&buffer, font, &renderer, lyricsStore, currentTime)
        
        guard let base = buffer.__dataUnsafe() else { return nil }
        let pixels = Data(bytes: base, count: buffer.sizeInBytes())
        
        guard let provider:CGDataProvider = CGDataProvider(data: pixels as CFData),
                let colorSpace:CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        else { return nil }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Big.rawValue)
        
        return CGImage(
            width: Int(buffer.width()),
            height: Int(buffer.height()),
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: Int(buffer.bytesPerRow()),
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    private static func loadFont(from data: Data, into font: inout karamock.Font) -> Bool {
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return false
            }
            return font.loadFromMemory(baseAddress, rawBuffer.count)
        }
    }
}
