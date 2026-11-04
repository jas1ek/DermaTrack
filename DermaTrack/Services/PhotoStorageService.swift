//
//  PhotoStorageService.swift
//  DermaTrack
//
//  Created by Julia Marek on 04/11/2026.
//


import Foundation
import Supabase

private struct NewBackendPhoto: Encodable {
    let lesion_id: UUID
    let storage_path: String
}

struct PhotoStorageService {

    private let client = SupabaseManager.shared.client

    func addPhoto(
        to lesionID: UUID,
        imageData: Data
    ) async throws -> String {

        let user = try await client.auth.user()

        let userID = user.id.uuidString.lowercased()
        let lesion = lesionID.uuidString.lowercased()
        let photoID = UUID().uuidString.lowercased()

        let path = "\(userID)/\(lesion)/\(photoID).jpg"

        // 1. Upload do prywatnego Storage
        try await client.storage
            .from("lesion-photos")
            .upload(
                path: path,
                file: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: false
                )
            )

        // 2. Zapis informacji o zdjeciu w PostgreSQL
        do {
            let photo = NewBackendPhoto(
                lesion_id: lesionID,
                storage_path: path
            )

            try await client
                .from("lesion_photos")
                .insert(photo)
                .execute()

        } catch {
            // Usuwamy plik, jesli nie zapisano metadanych
            do {
                try await client.storage
                    .from("lesion-photos")
                    .remove(paths: [path])
            } catch {
                // Wymaga pozniejszego sprawdzenia
                // i usuniecia osieroconego pliku.
            }

            throw error
        }

        return path
    }
}

