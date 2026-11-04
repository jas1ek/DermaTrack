//
//  LesionBackendService.swift
//  DermaTrack
//
//  Created by Julia Marek on 04/11/2026.
//


import Foundation
import Supabase

// Dane przesylane do PostgreSQL
private struct NewBackendLesion: Encodable {
    let user_id: UUID
    let name: String
    let body_location: String
    let description: String?
}

// Odpowiedz bazy po dodaniu znamienia
struct BackendLesionRecord: Decodable {
    let id: UUID
}

struct LesionBackendService {

    private let client = SupabaseManager.shared.client

    func createLesion(
        name: String,
        bodyLocation: String,
        description: String?
    ) async throws -> UUID {

        let user = try await client.auth.user()

        let lesion = NewBackendLesion(
            user_id: user.id,
            name: name,
            body_location: bodyLocation,
            description: description
        )

        let result: BackendLesionRecord = try await client
            .from("lesions")
            .insert(lesion)
            .select("id")
            .single()
            .execute()
            .value

        return result.id
    }
}

