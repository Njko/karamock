//
//  TextRenderer.hpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#pragma once
#include <cstdint>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace karamock {

class Font;
class PixelBuffer;

struct Color { std::uint8_t r,g,b; };

class TextRenderer {
public:
    void drawText(PixelBuffer& target, const Font& font, const std::string& text,
                  int x, int baselineY, float pixelHeight, Color color);
    int measureWidth(const Font& font, const std::string& text, float pixelHeight) const;

private:
    struct CachedGlyph {
        std::vector<std::uint8_t> bitmap;  // w*h valeurs alpha (vide si glyphe invisible)
        int w = 0, h = 0;
        int ix0 = 0, iy0 = 0;             // offset bbox dans l'espace de dessin
        int advance = 0;                   // font units — multiplier par scale pour obtenir pixels
        int leftBearing = 0;
    };

    // Clé : 48 bits hauts = codepoint, 16 bits bas = pixelHeight arrondi à l'entier
    static std::uint64_t glyphKey(int codepoint, float pixelHeight);

    // Retourne le glyphe du cache (ou le rasterise et le met en cache si absent)
    // fi est de type stbtt_fontinfo* — défini dans stb_truetype.h inclus dans le .cpp uniquement
    const CachedGlyph& fetchGlyph(const void* fi, int codepoint, float scale, float pixelHeight);

    std::unordered_map<std::uint64_t, CachedGlyph> glyphCache_;
    // hmetricsCache_ est mutable car c'est un cache logique utilisé dans measureWidth (const)
    mutable std::unordered_map<int, std::pair<int, int>> hmetricsCache_;
};

}
