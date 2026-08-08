//
//  Untitled.hpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#pragma once
#include <cstddef>
#include <cstdint>
#include <vector>

namespace karamock {

class PixelBuffer {
public:
    PixelBuffer() = default;
    
    void resize(int width, int height);
    void fillTestPattern();
    
    int width() const;
    int height() const;
    int bytesPerRow() const;
    std::size_t sizeInBytes() const;
    const std::uint8_t* data() const;
    
private:
    int width_ = 0;
    int height_ = 0;
    std::vector<std::uint8_t> pixels_;
};
} // namespace karamock
