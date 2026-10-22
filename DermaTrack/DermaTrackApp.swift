//
//  DermaTrackApp.swift
//  DermaTrack
//
//  Created by Jan Bobrzyk on 09/10/2026.
//


import SwiftUI

@main
struct DermaTrackApp: App {

    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            AuthRootView(auth: auth)
        }
    }
}

