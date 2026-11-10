//
//  LesionBackendService.swift
//  DermaTrack
//
//  Created by Julia Marek on 04/11/2026.
//

import Foundation
import Supabase

// MARK: - Model rekordu pobieranego z PostgreSQL

private struct BackendLesion: Decodable {

    let id: UUID
    let name: String
    let bodyLocation: String
    let description: String?
    let createdAt: String

    let mapSide: String?
    let mapX: Double?
    let mapY: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bodyLocation = "body_location"
        case description
        case createdAt = "created_at"
        case mapSide = "map_side"
        case mapX = "map_x"
        case mapY = "map_y"
    }

    func toLesion() throws -> Lesion {

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        guard let date =
            formatter.date(from: createdAt) ??
            fallbackFormatter.date(from: createdAt)
        else {
            throw LesionBackendError.invalidDate(createdAt)
        }

        return Lesion(
            id: id,
            name: name,
            location: bodyLocation,
            createdAt: date,
            notes: description ?? "",
            mapSide: mapSide,
            mapX: mapX,
            mapY: mapY
        )
    }
}

// MARK: - Dane wysyłane podczas tworzenia znamienia

private struct NewBackendLesion: Encodable {

    let id: UUID
    let userID: UUID
    let name: String
    let bodyLocation: String
    let description: String?
    let createdAt: String

    let mapSide: String?
    let mapX: Double?
    let mapY: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case bodyLocation = "body_location"
        case description
        case createdAt = "created_at"
        case mapSide = "map_side"
        case mapX = "map_x"
        case mapY = "map_y"
    }
}

// MARK: - Dane wysyłane podczas aktualizacji

private struct UpdateBackendLesion: Encodable {

    let name: String
    let bodyLocation: String
    let description: String?

    let mapSide: String?
    let mapX: Double?
    let mapY: Double?

    enum CodingKeys: String, CodingKey {
        case name
        case bodyLocation = "body_location"
        case description
        case mapSide = "map_side"
        case mapX = "map_x"
        case mapY = "map_y"
    }
}

// MARK: - Odpowiedź zawierająca UUID

private struct BackendLesionID: Decodable {
    let id: UUID
}

// MARK: - Błędy

enum LesionBackendError: LocalizedError {

    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Nie udało się odczytać daty utworzenia znamienia."
        }
    }
}

// MARK: - Główny serwis Supabase

struct LesionBackendService {

    private let client = SupabaseManager.shared.client

    // MARK: - Pobieranie znamion

    func fetchLesions() async throws -> [Lesion] {

        let user = try await client.auth.user()

        let records: [BackendLesion] = try await client
            .from("lesions")
            .select("""
                id,
                name,
                body_location,
                description,
                created_at,
                map_side,
                map_x,
                map_y
                """)
            .eq("user_id", value: user.id.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return try records.map { try $0.toLesion() }
    }

    // MARK: - Dodawanie znamienia z zachowaniem UUID

    func createLesion(_ lesion: Lesion) async throws {

        let user = try await client.auth.user()

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        let record = NewBackendLesion(
            id: lesion.id,
            userID: user.id,
            name: lesion.name,
            bodyLocation: lesion.location,
            description: lesion.notes,
            createdAt: dateFormatter.string(from: lesion.createdAt),
            mapSide: lesion.mapSide,
            mapX: lesion.mapX,
            mapY: lesion.mapY
        )

        let inserted: BackendLesionID = try await client
            .from("lesions")
            .insert(record)
            .select("id")
            .single()
            .execute()
            .value

        guard inserted.id == lesion.id else {
            throw NSError(
                domain: "DermaTrack.LesionBackend",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "UUID zapisanego znamienia jest niezgodny."
                ]
            )
        }
    }

    // MARK: - Zgodność ze starszym API backendu

    func createLesion(
        name: String,
        bodyLocation: String,
        description: String?
    ) async throws -> UUID {

        let lesion = Lesion(
            name: name,
            location: bodyLocation,
            notes: description ?? ""
        )

        try await createLesion(lesion)

        return lesion.id
    }

    // MARK: - Aktualizacja znamienia

    func updateLesion(_ lesion: Lesion) async throws {

        let user = try await client.auth.user()

        let record = UpdateBackendLesion(
            name: lesion.name,
            bodyLocation: lesion.location,
            description: lesion.notes,
            mapSide: lesion.mapSide,
            mapX: lesion.mapX,
            mapY: lesion.mapY
        )

        let updated: BackendLesionID = try await client
            .from("lesions")
            .update(record)
            .eq("id", value: lesion.id.uuidString)
            .eq("user_id", value: user.id.uuidString)
            .select("id")
            .single()
            .execute()
            .value

        guard updated.id == lesion.id else {
            throw NSError(
                domain: "DermaTrack.LesionBackend",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Nie udało się potwierdzić aktualizacji znamienia."
                ]
            )
        }
    }

    // MARK: - Usuwanie znamienia

    func deleteLesion(id: UUID) async throws {

        let user = try await client.auth.user()

        let deleted: BackendLesionID = try await client
            .from("lesions")
            .delete()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: user.id.uuidString)
            .select("id")
            .single()
            .execute()
            .value

        guard deleted.id == id else {
            throw NSError(
                domain: "DermaTrack.LesionBackend",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Nie udało się potwierdzić usunięcia znamienia."
                ]
            )
        }
    }
}
