//
//  ContentView.swift
//  DermaTrack
//
//  Created by Jan Bobrzyk on 09/10/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Start", systemImage: "house")
                }

            LesionsListView()
                .tabItem {
                    Label("Znamiona", systemImage: "list.bullet")
                }

            BodyMapView()
                .tabItem {
                    Label("Mapa ciała", systemImage: "figure.stand")
                }

            SettingsView()
                .tabItem {
                    Label("Ustawienia", systemImage: "gearshape")
                }
        }
        .tint(.teal)
    }
}

#Preview {
    ContentView()
}
