//
//  LyricsStore.hpp
//  Karamock
//
//  Created by A422GQ on 06/08/2026.
//

#pragma once
#include <string>
#include <vector>
#include <cstddef>

namespace karamock {

struct LyricLine {
    double time;
    std::string text;
};

class LyricsStore {
public:
    LyricsStore() = default;
    void reserve(std::size_t count);
    void addLine(double time, const std::string& text);
    void clear();
    
    std::size_t lineCount() const;
    double timeAt(std::size_t index) const;
    
private:
    std::vector<LyricLine> lines_;
};

} // namespace karamock
