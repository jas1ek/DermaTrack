//
//  RoleSecurityTestView.swift
//  DermaTrack
//
//  Created by Julia Marek on 29/10/2026.
//


import SwiftUI
import Supabase

struct RoleSecurityTestView: View {

    @State private var status = "Test nie został wykonany"
    @State private var isTesting = false

    private let client = SupabaseManager.shared.client

    var body: some View {
        VStack(spacing: 16) {

            Text("Test eskalacji uprawnień")
                .font(.headline)

            Button("Spróbuj zmienić rolę na dermatologa") {
                Task {
                    await testRoleChange()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTesting)

            Text(status)
                .font(.caption)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            if isTesting {
                ProgressView()
            }
        }
        .padding()
    }

    private func testRoleChange() async {
        isTesting = true
        defer { isTesting = false }

        do {
            let user = try await client.auth.user()

            try await client
                .from("profiles")
                .update(["role": "dermatologist"])
                .eq("id", value: user.id.uuidString.lowercased())
                .execute()

            // Sprawdzamy rzeczywisty stan bazy
            let profile = try await ProfileService()
                .getCurrentProfile()

            if profile.role == .dermatologist {
                status = "BŁĄD BEZPIECZEŃSTWA: rola została zmieniona!"
            } else {
                status = "Rola pozostała bez zmian: \(profile.role.rawValue)"
            }

        } catch {
            status = """
            TEST ZABLOKOWANY
            \(error.localizedDescription)
            """
        }
    }
}

#Preview {
    RoleSecurityTestView()
}

