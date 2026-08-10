//
//  TextRenderer.cpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#include "TextRenderer.hpp"
#include "Font.hpp"
#include "PixelBuffer.hpp"
#include "stb_truetype.h"

namespace karamock {

// Cache des glyphes rasterisés — élimine stbtt_MakeCodepointBitmap sur les frames suivantes.
// Clé : codepoint encodé sur 48 bits hauts | pixelHeight arrondi sur 16 bits bas.
std::uint64_t TextRenderer::glyphKey(int codepoint, float pixelHeight) {
    const std::uint32_t h = static_cast<std::uint32_t>(static_cast<int>(pixelHeight + 0.5f));
    return (static_cast<std::uint64_t>(static_cast<std::uint32_t>(codepoint)) << 16) | h;
}

const TextRenderer::CachedGlyph& TextRenderer::fetchGlyph(const void* fi, int codepoint,
                                                           float scale, float pixelHeight) {
    const stbtt_fontinfo* fontInfo = static_cast<const stbtt_fontinfo*>(fi);
    const std::uint64_t key = glyphKey(codepoint, pixelHeight);
    auto it = glyphCache_.find(key);
    if (it != glyphCache_.end()) {
        return it->second;
    }

    CachedGlyph g;
    stbtt_GetCodepointHMetrics(fontInfo, codepoint, &g.advance, &g.leftBearing);

    int ix1, iy1;
    stbtt_GetCodepointBitmapBox(fontInfo, codepoint, scale, scale, &g.ix0, &g.iy0, &ix1, &iy1);
    g.w = ix1 - g.ix0;
    g.h = iy1 - g.iy0;
    if (g.w > 0 && g.h > 0) {
        g.bitmap.resize(static_cast<std::size_t>(g.w) * g.h);
        stbtt_MakeCodepointBitmap(fontInfo, g.bitmap.data(), g.w, g.h, g.w, scale, scale, codepoint);
    }
    return glyphCache_.emplace(key, std::move(g)).first->second;
}

void TextRenderer::drawText(PixelBuffer &target, const Font &font, const std::string &text,
                            int x, int baselineY, float pixelHeight, Color color) {
    if (!font.isValid()) {
        return;
    }
    
    const stbtt_fontinfo* fontInfo = static_cast<const stbtt_fontinfo*>(font.nativeHandle());
    const float scale = font.scaleForPixelsHeight(pixelHeight);
    float xpos = static_cast<float>(x);
    
    for(std::size_t k = 0; k < text.size(); ++k) {
        const int c = static_cast<unsigned char>(text[k]);
        const CachedGlyph& g = fetchGlyph(static_cast<const void*>(fontInfo), c, scale, pixelHeight);

        if (!g.bitmap.empty()) {
            for (int gy = 0; gy < g.h; ++gy) {
                for (int gx = 0; gx < g.w; ++gx) {
                    const std::uint8_t coverage = g.bitmap[static_cast<std::size_t>(gy) * g.w + gx];
                    if (coverage != 0) {
                        target.blendPixel(static_cast<int>(xpos) + g.ix0 + gx,
                                          baselineY + g.iy0 + gy,
                                          color.r, color.g, color.b, coverage);
                    }
                }
            }
        }
        
        xpos += g.advance * scale;
        if (k + 1 < text.size()) {
            xpos += scale * stbtt_GetCodepointKernAdvance(fontInfo, c, static_cast<unsigned char>(text[k + 1]));
        }
    }
}

int TextRenderer::measureWidth(const Font &font, const std::string &text, float pixelHeight) const {
    if (!font.isValid()) {
        return 0;
    }
    
    const stbtt_fontinfo* fontInfo = static_cast<const stbtt_fontinfo*>(font.nativeHandle());
    const float scale = font.scaleForPixelsHeight(pixelHeight);
    float width = 0.0f;
    
    for (std::size_t k = 0; k < text.size(); ++k) {
        const int c = static_cast<unsigned char>(text[k]);

        auto it = hmetricsCache_.find(c);
        if (it == hmetricsCache_.end()) {
            int advance = 0, lb = 0;
            stbtt_GetCodepointHMetrics(fontInfo, c, &advance, &lb);
            it = hmetricsCache_.emplace(c, std::make_pair(advance, lb)).first;
        }
        width += it->second.first * scale;

        if (k + 1 < text.size()) {
            width += scale * stbtt_GetCodepointKernAdvance(fontInfo, c, static_cast<unsigned char>(text[k + 1]));
        }
    }
    return static_cast<int>(width);
}
}
