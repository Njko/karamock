//
//  Song+Duration.swift
//  Karamock
//
//  Created by A422GQ on 29/07/2026.
//

import Foundation

extension Song {
    nonisolated var durationInSeconds: TimeInterval {
        let parts = duration.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}
