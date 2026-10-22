//
//  AuthService.swift
//  DermaTrack
//
//  Created by Julia Marek on 11/10/2026.
//

import Foundation
import Supabase

final class AuthService {

    static let shared = AuthService()

    private let client = SupabaseManager.shared.client

    private init() {}

    func register(
        email: String,
        password: String
    ) async throws {
        _ = try await client.auth.signUp(
            email: email,
            password: password
        )
    }

    func login(
        email: String,
        password: String
    ) async throws {
        _ = try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func logout() async throws {
        try await client.auth.signOut()
    }

    func currentUserID() -> UUID? {
        client.auth.currentUser?.id
    }

    func isLoggedIn() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }
}

