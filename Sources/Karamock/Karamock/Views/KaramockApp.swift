//
//  KaramockApp.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI

@main
struct KaramockApp: App {
    
    @State var player = PlayerState()
    @State var downloadedSongsRepository = InMemoryDownloadedSongsRepository()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.player, player)
                .environment(\.downloadedSongsRepository, downloadedSongsRepository)
        }
    }
}
