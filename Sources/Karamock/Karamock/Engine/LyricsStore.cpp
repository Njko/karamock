//
//  LyricsStore.cpp
//  Karamock
//
//  Created by A422GQ on 06/08/2026.
//

#include "LyricsStore.hpp"

namespace karamock {

void LyricsStore::reserve(std::size_t count) {
    lines_.reserve(count);
}

void LyricsStore::addLine(double time, const std::string &text) {
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

} // namespace karamock
