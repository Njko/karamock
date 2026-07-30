//
//  Playlist+GradientColors.swift
//  Karamock
//
//  Created by A422GQ on 29/07/2026.
//

import SwiftUI

extension Playlist {
    var gradientColors: [Color] {
        switch title {
        case "Best Of Rock":
            return [.red, .orange]
        case "Années 2000\nen France":
            return [.blue, .green]
        case "Karaoké\nClassics":
            return [.yellow, .purple]
        default:
            return [.gray]
        }
    }
}
