//
//  AuthRootView.swift
//  DermaTrack
//
//  Created by Julia Marek on 18/10/2026.
//


import SwiftUI

struct AuthRootView: View {

    @ObservedObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView("Sprawdzanie sesji...")

            } else if auth.isLoggedIn {
                patientView

            } else {
                LoginView(auth: auth)
            }
        }
        .task {
            await auth.restoreSession()
        }
    }

    private var patientView: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("DermaTrack")
                    .font(.largeTitle)
                    .bold()

                Text("Zalogowano pomyślnie")
                    .font(.headline)

                Text("Witaj w panelu pacjenta")
                    .foregroundStyle(.secondary)

                Button("Wyloguj się") {
                    Task {
                        await auth.logout()
                    }
                }
                .buttonStyle(.borderedProminent)

            }
            .padding()
            .navigationTitle("Panel pacjenta")
        }
    }
}

#Preview {
    AuthRootView(auth: AuthViewModel())
}

