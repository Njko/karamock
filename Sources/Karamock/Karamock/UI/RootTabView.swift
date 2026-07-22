//
//  RootTabView.swift
//  Karamock
//
//  Created by A422GQ on 21/07/2026.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            DiscoveryView()
                .tabItem {
                    Label("Découvrir", systemImage: "book.closed.fill")
                }
            LibraryView()
                .tabItem {
                    Label("Bibliothèque", systemImage: "music.note.list")
                }
        }
    }
}
