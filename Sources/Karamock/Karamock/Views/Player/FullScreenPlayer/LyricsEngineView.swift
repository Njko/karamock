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
    let lyrics: [LyricsLine]
    let currentTime: TimeInterval
    
    @Environment(\.displayScale) private var displayScale
    @State private var engine = LyricsRenderEngine()
    @State private var image: CGImage?
    @State private var fontData: Data?
    @State private var size: CGSize = .zero
    @State private var isRendering = false
    @State private var pendingRequest: FrameRequest?
    
    private struct FrameRequest: Equatable {
        let timeMillis: Int
        let width: Int
        let height: Int
    }
    
    private var request: FrameRequest {
        FrameRequest(timeMillis: Int((currentTime * 1000).rounded()),
                     width: Int((size.width * displayScale).rounded()),
                     height: Int((size.height * displayScale).rounded())
        )
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .task { await loadFontAndLyrics() }
            .task(id: lyrics) { await pushLyrics()}
            .task(id: request) { await renderCurrent() }

    }
    
    @ViewBuilder
    private var content: some View {
        if let image {
            Image(decorative: image, scale: displayScale)
                .resizable()
                .interpolation(.none)
        } else {
            ProgressView()
        }
    }

    private func loadFontAndLyrics() async {
        if fontData == nil,
           let url = Bundle.main.url(forResource: "NotoSans-Regular", withExtension: "ttf") {
            fontData = try? Data(contentsOf: url)
        }
        
        if let fontData { await engine.loadFontIfNeeded(fontData) }
        await pushLyrics()
    }
    
    private func pushLyrics() async {
        let payload = lyrics.map { LyricsLinePayload(time: $0.time, text: $0.text) }
        await engine.setLyrics(payload)
    }
    
    // Rendu coalescé : un seul frame en vol à la fois. Les ticks qui arrivent
    // pendant un rendu ne s'empilent pas sur l'acteur — on ne garde que le plus
    // récent (pendingRequest) et on le rend dès que l'acteur se libère.
    private func renderCurrent() async {
        let req = request
        guard req.width > 0, req.height > 0 else { return }

        guard !isRendering else {
            pendingRequest = req
            return
        }

        isRendering = true
        var next: FrameRequest? = req
        while let r = next {
            let frame = await engine.frame(
                at: Double(r.timeMillis) / 1000.0,
                pixelWidth: r.width,
                pixelHeight: r.height
            )
            if let frame {
                image = Self.makeCGImage(from: frame, scale: displayScale)
            }
            next = pendingRequest
            pendingRequest = nil
        }
        isRendering = false
    }
    
    private static func makeCGImage(from frame: RenderedFrame, scale: CGFloat) -> CGImage? {
        guard let provider = CGDataProvider(data: frame.rgba as CFData),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Big.rawValue
        )
        return CGImage(
            width: frame.width, height: frame.height,
            bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: frame.bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
