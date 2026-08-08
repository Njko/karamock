//
//  LyricsPage.cpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#include "LyricsPage.hpp"
#include "Font.hpp"
#include "PixelBuffer.hpp"
#include "TextRenderer.hpp"
#include "LyricsStore.hpp"

namespace karamock {

namespace {

Color dim(Color c) {
    return Color {
        static_cast<std::uint8_t>(c.r / 3),
        static_cast<std::uint8_t>(c.g / 3),
        static_cast<std::uint8_t>(c.b / 3)
    };
}

void drawCentered(PixelBuffer& target, const Font& font, TextRenderer& renderer, const std::string& text, int baselineY, float pixelHeight, Color color) {
    const int width = renderer.measureWidth(font, text, pixelHeight);
    const int x = (target.width() - width) / 2;
    renderer.drawText(target, font, text, x, baselineY, pixelHeight, color);
}

} // namespace

void LyricsPage::render(PixelBuffer& target, const Font& font, TextRenderer& renderer, const LyricsStore& lyrics, double currentTime) const {
    const std::size_t active = lyrics.indexAtTime(currentTime);
    if (active == LyricsStore::npos) {
        return; // rien avant la premiere ligne
    }
    
    constexpr float activeHeight = 56.0f;
    constexpr float sideHeight = 32.0f;
    const Color activeColor{240, 240, 245};
    const Color sideColor = dim(activeColor);
    
    int ascent = 0, descent = 0, lineGap = 0;
    font.verticalMetrics(&ascent, &descent, &lineGap);
    const float lineAdvance = (ascent - descent + lineGap) * font.scaleForPixelsHeight(activeHeight);
    
    const int centerY = target.height() / 2;
    drawCentered(target, font, renderer, lyrics.textAt(active), centerY, activeHeight, activeColor);
    
    if (active > 0) {
        drawCentered(target, font, renderer, lyrics.textAt(active - 1), centerY - static_cast<int>(lineAdvance), sideHeight, sideColor);
    }
    
    if (active + 1 < lyrics.lineCount()) {
        drawCentered(target, font, renderer, lyrics.textAt(active + 1), centerY + static_cast<int>(lineAdvance), sideHeight, sideColor);
    }
}

} // namespace karamock
