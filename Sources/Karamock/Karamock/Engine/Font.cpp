//
//  Font.cpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#include "Font.hpp"
#include "stb_truetype.h"

namespace karamock {

struct Font::Impl {
    std::vector<std::uint8_t> ttf;
    stbtt_fontinfo info{};
    bool valid = false;
};

Font::Font() : impl_(std::make_unique<Impl>()) {}
Font::~Font() = default;
Font::Font(Font&&) noexcept = default;
Font& Font::operator=(Font&&) noexcept = default;

bool Font::loadFromMemory(std::vector<std::uint8_t> ttfBytes) {
    impl_->ttf = std::move(ttfBytes);
    const int offset = stbtt_GetFontOffsetForIndex(impl_->ttf.data(), 0);
    impl_->valid = offset >= 0 && stbtt_InitFont(&impl_->info, impl_->ttf.data(), offset) != 0;
    return impl_->valid;
}

bool Font::loadFromMemory(const std::uint8_t *bytes, std::size_t count) {
    if (!bytes || count == 0) {
        impl_->valid = false;
        return false;
    }
    std::vector<std::uint8_t> ttfBytes(bytes, bytes + count);
    return loadFromMemory(std::move(ttfBytes));
}

bool Font::isValid() const { return impl_->valid; }

float Font::scaleForPixelsHeight(float pixelHeight) const {
    return stbtt_ScaleForPixelHeight(&impl_->info, pixelHeight);
}

void Font::verticalMetrics(int *ascent, int *descent, int *lineGap) const {
    stbtt_GetFontVMetrics(&impl_->info, ascent, descent, lineGap);
}

const void* Font::nativeHandle() const {
    return &impl_->info;
}

}
