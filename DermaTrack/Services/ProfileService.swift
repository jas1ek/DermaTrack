//
//  ProfileService.swift
//  DermaTrack
//
//  Created by Julia Marek on 29/10/2026.
//


import Foundation
import Supabase

struct ProfileService {

    private let client = SupabaseManager.shared.client

    func getCurrentProfile() async throws -> UserProfile {
        let user = try await client.auth.user()

        let profile: UserProfile = try await client
            .from("profiles")
            .select("id, display_name, role")
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
            .value

        return profile
    }
}

