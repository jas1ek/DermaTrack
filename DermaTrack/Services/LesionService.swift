
import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class LesionService: ObservableObject {
    @Published private(set) var lesions: [Lesion] = []
    @Published private(set) var photoVersion = 0

    private let storageKey = "dermatrack.lesions.v1"

    init() {
        load()
    }

    func add(_ lesion: Lesion) {
        lesions.append(lesion)
        save()
    }

    func update(_ lesion: Lesion) {
        guard let index = lesions.firstIndex(
            where: { $0.id == lesion.id }
        ) else {
            return
        }

        lesions[index] = lesion
        save()
    }

    func delete(id: UUID) {
        lesions.removeAll { $0.id == id }

        let directory = photoDirectory(for: id)
        try? FileManager.default.removeItem(at: directory)

        save()
        photoVersion += 1
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { lesions[$0].id }

        for id in ids {
            delete(id: id)
        }
    }

    func addPhoto(_ data: Data, to lesionID: UUID) throws {
        guard lesions.contains(where: { $0.id == lesionID }) else {
            throw PhotoError.invalidLesion
        }

        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(
                compressionQuality: 0.85
              ) else {
            throw PhotoError.invalidImage
        }

        let directory = photoDirectory(for: lesionID)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let timestamp = Int(
            Date().timeIntervalSince1970 * 1000
        )

        let filename = "\(timestamp)-\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)

        try jpegData.write(to: url, options: .atomic)
        photoVersion += 1
    }

    func photoURLs(for lesionID: UUID) -> [URL] {
        let directory = photoDirectory(for: lesionID)

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return files
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted {
                $0.lastPathComponent < $1.lastPathComponent
            }
    }

    func deletePhoto(at url: URL, for lesionID: UUID) {
        let directory = photoDirectory(for: lesionID)

        guard url.deletingLastPathComponent()
            .standardizedFileURL == directory.standardizedFileURL else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
            photoVersion += 1
        } catch {
            print("Błąd usuwania zdjęcia: \(error)")
        }
    }

    private func photoDirectory(for id: UUID) -> URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        return documents
            .appendingPathComponent("LesionPhotos", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(lesions)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Błąd zapisu: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return
        }

        do {
            lesions = try JSONDecoder().decode(
                [Lesion].self,
                from: data
            )
        } catch {
            print("Błąd odczytu: \(error)")
        }
    }

    enum PhotoError: Error {
        case invalidLesion
        case invalidImage
    }
}
