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
    @State private var image: CGImage?
    
    private let pointSize = CGSize(width: 240, height: 135)
    
    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: displayScale)
                    .interpolation(.none)
            } else {
                ProgressView()
            }
        }
        .frame(width: pointSize.width, height: pointSize.height)
        .task (id: displayScale) {
            image = Self.render(pointSize: pointSize, scale: displayScale)
        }
    }
    
    private static func render(pointSize: CGSize, scale: CGFloat) -> CGImage? {
        let pixelWidth: Int = Int((pointSize.width * scale).rounded())
        let pixelHeight: Int = Int((pointSize.height * scale).rounded())
        
        var buffer = karamock.PixelBuffer()
        buffer.resize(Int32(pixelWidth), Int32(pixelHeight))
        buffer.fillTestPattern()
        
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
}
