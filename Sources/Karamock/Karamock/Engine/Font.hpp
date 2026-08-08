//
//  Font.hpp
//  Karamock
//
//  Created by A422GQ on 08/08/2026.
//

#pragma once
#include <cstdint>
#include <memory>
#include <vector>

namespace karamock {

class Font {
    
public:
    Font();
    ~Font();
    Font(Font&&) noexcept;
    Font& operator=(Font&&) noexcept;
    Font(const Font&) = delete;
    Font& operator=(const Font&) = delete;
    
    bool loadFromMemory(std::vector<std::uint8_t> ttfBytes);
    bool loadFromMemory(const std::uint8_t* bytes, std::size_t count);
    bool isValid() const;
    
    float scaleForPixelsHeight(float pixelHeight) const;
    void verticalMetrics(int* ascent, int* descent, int* lineGap) const;
    
private:
    const void* nativeHandle() const;
    
    struct Impl;
    std::unique_ptr<Impl> impl_;
    friend class TextRenderer;
};

}
