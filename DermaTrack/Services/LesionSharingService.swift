//
//  LesionSharingService.swift
//  DermaTrack
//
//  Created by Julia Marek on 04/11/2026.
//


import Foundation
import Supabase

private struct NewLesionShare: Encodable {
    let lesion_id: UUID
    let patient_id: UUID
    let dermatologist_id: UUID
}

struct LesionSharingService {

    private let client = SupabaseManager.shared.client

    func shareLesion(
        lesionID: UUID,
        dermatologistID: UUID
    ) async throws {

        // Pobierz zalogowanego pacjenta
        let user = try await client.auth.user()

        // Przygotuj udostepnienie
        let share = NewLesionShare(
            lesion_id: lesionID,
            patient_id: user.id,
            dermatologist_id: dermatologistID
        )

        // Zapisz udostepnienie w Supabase
        try await client
            .from("lesion_shares")
            .insert(share)
            .execute()
    }
    
    
    func revokeShare(
        lesionID: UUID,
        dermatologistID: UUID
    ) async throws {

        let user = try await client.auth.user()

        try await client
            .from("lesion_shares")
            .delete()
            .eq("lesion_id", value: lesionID.uuidString.lowercased())
            .eq(
                "dermatologist_id",
                value: dermatologistID.uuidString.lowercased()
            )
            .eq("patient_id", value: user.id.uuidString.lowercased())
            .execute()
    }

}

