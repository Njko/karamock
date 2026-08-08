//
//  LyricsStore.cpp
//  Karamock
//
//  Created by A422GQ on 06/08/2026.
//

#include "LyricsStore.hpp"
#include <algorithm>
#include <cassert>

namespace karamock {

void LyricsStore::reserve(std::size_t count) {
    lines_.reserve(count);
}

void LyricsStore::addLine(double time, const std::string &text) {
    assert(lines_.empty() || time >= lines_.back().time);
    lines_.push_back(LyricLine{time, text});
}

void LyricsStore::clear() {
    lines_.clear();
}

std::size_t LyricsStore::lineCount() const {
    return lines_.size();
}

double LyricsStore::timeAt(std::size_t index) const {
    return lines_[index].time;
}

const std::string& LyricsStore::textAt(std::size_t index) const {
    return lines_[index].text;
}

std::size_t LyricsStore::indexAtTime(double time) const {
    if (lines_.empty() || time < lines_.front().time) {
        return npos;
    }
    const auto it = std::upper_bound(lines_.begin(), lines_.end(), time, [](double t, const LyricLine& line){
        return t < line.time;
    });
    return static_cast<std::size_t>(it - lines_.begin() - 1);
}
} // namespace karamock
