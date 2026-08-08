//
//  LyricsPage.hpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#pragma once

namespace karamock {

class Font;
class PixelBuffer;
class TextRenderer;
class LyricsStore;

class LyricsPage {
public:
    void render(PixelBuffer& target, const Font& font, TextRenderer& renderer, const LyricsStore& lyrics, double currentTime) const;
};

}
