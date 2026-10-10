//
//  BackendConnectionTestView.swift
//  DermaTrack
//
//  Created by Julia Marek on 10/10/2026.
//


import SwiftUI
import Supabase

private struct HealthCheck: Decodable {
    let id: Int
    let message: String
}

struct BackendConnectionTestView: View {

    @State private var message = "Oczekiwanie na test"
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {

            Text("DermaTrack")
                .font(.largeTitle)
                .bold()

            Text("Test polaczenia z Supabase")

            Text(message)
                .multilineTextAlignment(.center)

            Button("Sprawdz polaczenie") {
                Task {
                    await checkConnection()
                }
            }
            .disabled(isLoading)
            .buttonStyle(.borderedProminent)

        }
        .padding()
    }

    @MainActor
    private func checkConnection() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let client = SupabaseManager.shared.client

            let result: [HealthCheck] = try await client
                .from("app_health")
                .select()
                .eq("id", value: 1)
                .execute()
                .value

            message = result.first?.message
                ?? "Brak rekordu testowego"

        } catch {
            message = "Blad: \(error.localizedDescription)"
        }
    }
}

#Preview {
    BackendConnectionTestView()
}

