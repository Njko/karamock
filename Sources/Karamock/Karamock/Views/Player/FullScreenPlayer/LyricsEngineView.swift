//
//  EngineProofView.swift
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

import CoreGraphics
import Foundation
import SwiftUI

struct LyricsEngineView: View {
    let lyricsStore: karamock.LyricsStore
    let currentTime: TimeInterval
    
    @Environment(\.displayScale) private var displayScale
    @State private var fontData: Data?
    @State private var size: CGSize = .zero
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                size = newValue
            }
            .task {
                guard fontData == nil else { return }
                guard let fontURL = Bundle.main.url(forResource: "NotoSans-Regular", withExtension: "ttf")
                else { return }
                fontData = try? Data(contentsOf: fontURL)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if let fontData, size.width > 0, size.height > 0,
           let image = Self.render(pointSize: size, scale: displayScale, fontData: fontData,
                                   lyricsStore : lyricsStore, currentTime: currentTime){
            Image(decorative: image, scale: displayScale)
                .interpolation(.none)
        } else {
            ProgressView()
        }
    }
    
    private static func render(pointSize: CGSize, scale: CGFloat, fontData: Data, lyricsStore: karamock.LyricsStore, currentTime: Double) -> CGImage? {
        let pixelWidth: Int = Int((pointSize.width * scale).rounded())
        let pixelHeight: Int = Int((pointSize.height * scale).rounded())
        
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }
        
        var font = karamock.Font()
        guard loadFont(from: fontData, into: &font) else { return nil }
        
        var buffer = karamock.PixelBuffer()
        buffer.resize(Int32(pixelWidth), Int32(pixelHeight))
        buffer.fill(20, 20, 30)
        
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
