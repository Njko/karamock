//
//  Utilities.swift
//  Karamock
//
//  Created by A422GQ on 23/07/2026.
//

import Foundation

func formatTime (_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    return String(format: "%02d:%02d", total / 60, total % 60)
}
