//
//  PixelBuffer.cpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#include "PixelBuffer.hpp"

namespace karamock {

void PixelBuffer::resize(int width, int height) {
    width_ = width > 0 ? width : 0;
    height_ = height > 0 ? height : 0;
    pixels_.assign(static_cast<std::size_t>(width_) * height_ * 4, 0);
}

void PixelBuffer::fillTestPattern() {
    const int lastX = width_ > 1 ? width_ - 1 : 1;
    const int lastY = height_ > 1 ? height_ - 1 : 1;
    
    for (int y = 0; y < height_; ++y) {
        for (int x = 0; x < width_; ++x) {
            const std::size_t i = (static_cast<std::size_t>(y) * width_ + x) * 4;
            const bool light = (((x / 32) + (y / 32)) % 2) == 0;
            
            pixels_[i + 0] = static_cast<std::uint8_t>(x * 255 / lastX);
            pixels_[i + 1] = static_cast<std::uint8_t>(y * 255 / lastY);
            pixels_[i + 2] = light ? 200 : 40;
            pixels_[i + 3] = 255;
        }
    }
}

int PixelBuffer::width() const { return width_; }
int PixelBuffer::height() const { return height_; }
int PixelBuffer::bytesPerRow() const { return width_ * 4; }
std::size_t PixelBuffer::sizeInBytes() const { return pixels_.size(); }
const std::uint8_t* PixelBuffer::data() const { return pixels_.data(); }
}
