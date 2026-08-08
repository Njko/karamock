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
        
        int advance = 0, leftBearing = 0;
        stbtt_GetCodepointHMetrics(fontInfo, c, &advance, &leftBearing);
        
        int ix0, iy0, ix1, iy1;
        stbtt_GetCodepointBitmapBox(fontInfo, c, scale, scale, &ix0, &iy0, &ix1, &iy1);
        const int w = ix1 - ix0;
        const int h = iy1 - iy0;
        
        if (w > 0 && h > 0) {
            glyphScratch_.assign(static_cast<std::size_t>(w) * h, 0);
            stbtt_MakeCodepointBitmap(fontInfo, glyphScratch_.data(), w, h, /*stride*/ w, scale, scale, c);
            
            for (int gy = 0; gy < h; ++gy) {
                for (int gx = 0; gx < w; ++gx) {
                    const std::uint8_t coverage = glyphScratch_[static_cast<std::size_t>(gy) * w + gx];
                    if (coverage != 0) {
                        target.blendPixel(static_cast<int>(xpos) + ix0 + gx, baselineY + iy0 + gy,
                                          color.r, color.g, color.b, coverage);
                    }
                }
            }
        }
        
        xpos += advance * scale;
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
        int advance = 0, leftBearing = 0;
        stbtt_GetCodepointHMetrics(fontInfo, c, &advance, &leftBearing);
        width += advance * scale;
        if (k + 1 < text.size()) {
            width += scale * stbtt_GetCodepointKernAdvance(fontInfo, c, static_cast<unsigned char>(text[k + 1]));
        }
    }
    return static_cast<int>(width);
}
}
