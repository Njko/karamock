//
//  PlaybackClock.swift
//  Karamock
//
//  Created by A422GQ on 10/08/2026.
//

import QuartzCore

@MainActor
@Observable
final class PlaybackClock {
    private var anchorMedia: TimeInterval = 0
    private var anchorHost: TimeInterval = CACurrentMediaTime()
    private(set) var isRunning = false
    
    func sync(to mediaTime: TimeInterval, running: Bool) {
        anchorMedia = mediaTime
        anchorHost = CACurrentMediaTime()
        isRunning = running
    }
    
    func currentTime() -> TimeInterval {
        guard isRunning else { return anchorMedia }
        return anchorMedia + (CACurrentMediaTime() - anchorHost)
    }
}
