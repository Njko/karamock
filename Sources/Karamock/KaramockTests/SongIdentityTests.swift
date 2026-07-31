//
//  SongIdentityTests.swift
//  Karamock
//
//  Created by A422GQ on 31/07/2026.
//

import Testing
@testable import Karamock

struct SongIdentityTests {
    
    @Test
    @MainActor
    func songWithSameArtistAndTitleShareTheSameIdentity() {
        let first = Song(title: "A title", artist: "An artist", year: 2004, duration: "2:01", key: "A")
        let second = Song(title: "A title", artist: "An artist", year: 2004, duration: "2:01", key: "A")
        
        #expect(first.id == second.id)
        #expect(first == second)
    }
}
