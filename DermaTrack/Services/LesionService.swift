import Foundation
import Combine
import UIKit

@MainActor
final class LesionService: ObservableObject {

    @Published private(set) var lesions: [Lesion] = []
    @Published private(set) var photoVersion = 0
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let backend = LesionBackendService()
    private var activeUserID: UUID?
    // Legacy UserDefaults data is deliberately NOT imported automatically.
    // Historical key: dermatrack.lesions.v1 - leave untouched for migration.

    func refresh() async {
        guard let userID = AuthService.shared.currentUserID() else {
            clearSession()
            errorMessage = "Brak sesji użytkownika. Zaloguj się ponownie."
            return
        }

        if activeUserID != userID {
            lesions = []
            activeUserID = userID
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let remote = try await backend.fetchLesions()
            guard activeUserID == userID,
                  AuthService.shared.currentUserID() == userID else { return }
            lesions = remote
        } catch {
            guard activeUserID == userID else { return }
            errorMessage = "Nie udało się pobrać znamion: \(error.localizedDescription)"
        }
    }

    func clearSession() {
        activeUserID = nil
        lesions = []
        errorMessage = nil
        isLoading = false
        photoVersion += 1
    }

    private func requireUser() throws -> UUID {
        guard let id = AuthService.shared.currentUserID(),
              activeUserID == id else { throw LesionError.missingSession }
        return id
    }

    func add(_ lesion: Lesion) async throws {
        let userID = try requireUser()
        try await backend.createLesion(lesion)
        guard activeUserID == userID,
              AuthService.shared.currentUserID() == userID else {
            throw LesionError.sessionChanged
        }
        // Update view only after successful remote insertion.
        lesions.append(lesion)
    }

    func update(_ lesion: Lesion) async throws {
        let userID = try requireUser()
        try await backend.updateLesion(lesion)
        guard activeUserID == userID,
              AuthService.shared.currentUserID() == userID else {
            throw LesionError.sessionChanged
        }
        guard let index = lesions.firstIndex(where: { $0.id == lesion.id }) else {
            return
        }
        lesions[index] = lesion
    }

    func delete(id: UUID) async throws {
        let userID = try requireUser()
        try await backend.deleteLesion(id: id)
        guard activeUserID == userID,
              AuthService.shared.currentUserID() == userID else {
            throw LesionError.sessionChanged
        }
        lesions.removeAll { $0.id == id }
        // Local photo cleanup happens only after confirmed deletion.
        try? FileManager.default.removeItem(at: photoDirectory(for: id, userID: userID))
        photoVersion += 1
    }

    func delete(at offsets: IndexSet) async throws {
        let ids = offsets.compactMap { index in
            lesions.indices.contains(index) ? lesions[index].id : nil
        }
        for id in ids { try await delete(id: id) }
    }

    // Until Storage integration, photos remain local AND are scoped to user ID.
    // Legacy Documents/LesionPhotos/<lesionId> files are preserved for migration,
    // but deliberately not visible between user accounts.
    func addPhoto(_ data: Data, to lesionID: UUID) throws {
        let userID = try requireUser()
        guard lesions.contains(where: { $0.id == lesionID }) else {
            throw PhotoError.invalidLesion
        }
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw PhotoError.invalidImage
        }
        let directory = photoDirectory(for: lesionID, userID: userID)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let filename = "\(timestamp)-\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        try jpegData.write(to: url, options: [.atomic, .completeFileProtection])
        photoVersion += 1
    }

    func photoURLs(for lesionID: UUID) -> [URL] {
        guard let userID = activeUserID,
              AuthService.shared.currentUserID() == userID,
              lesions.contains(where: { $0.id == lesionID }) else { return [] }
        let directory = photoDirectory(for: lesionID, userID: userID)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return [] }
        return files
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func deletePhoto(at url: URL, for lesionID: UUID) {
        guard let userID = try? requireUser(),
              lesions.contains(where: { $0.id == lesionID }) else { return }
        let directory = photoDirectory(for: lesionID, userID: userID)
        guard url.deletingLastPathComponent().standardizedFileURL
                == directory.standardizedFileURL else { return }
        do {
            try FileManager.default.removeItem(at: url)
            photoVersion += 1
        } catch {
            errorMessage = "Nie udało się usunąć lokalnego zdjęcia."
        }
    }

    private func photoDirectory(for id: UUID, userID: UUID) -> URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )[0]
        return documents
            .appendingPathComponent("LesionPhotos", isDirectory: true)
            .appendingPathComponent(userID.uuidString, isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
    }

    enum PhotoError: LocalizedError {
        case invalidLesion, invalidImage
        var errorDescription: String? {
            switch self {
            case .invalidLesion: return "Nie znaleziono znamienia."
            case .invalidImage: return "Nieprawidłowy obraz."
            }
        }
    }

    enum LesionError: LocalizedError {
        case missingSession, sessionChanged
        var errorDescription: String? {
            switch self {
            case .missingSession: return "Sesja pacjenta jest niedostępna."
            case .sessionChanged: return "Konto zmieniło się podczas operacji. Odśwież listę."
            }
        }
    }
}
