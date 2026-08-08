//
//  TextRenderer.hpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#pragma once
#include <cstdint>
#include <string>
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
    std::vector<std::uint8_t> glyphScratch_;
};

}
