//
//  DermatologistAccessTestView.swift
//  DermaTrack
//
//  Created by Julia Marek on 04/11/2026.
//



import SwiftUI
import UIKit
import Supabase

struct DermatologistAccessTestView: View {

    @State private var result = ""
    @State private var isWorking = false
    
    @State private var downloadedImage: UIImage?
    @State private var photoStatus = ""

    private let photoService = PhotoStorageService()

    private let client = SupabaseManager.shared.client

    private struct SharedLesion: Decodable {
        let id: UUID
        let name: String
        let body_location: String
    }

    var body: some View {
        VStack(spacing: 16) {

            Text("Test dostępu dermatologa")
                .font(.headline)

            Button("Pobierz udostępnione znamię") {
                Task {
                    await testAccess()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking)

            if isWorking {
                ProgressView()
            }

            Text(result)
                .font(.caption)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            
            Button("Pobierz zdjęcie znamienia") {
                Task {
                    await testPhotoAccess()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isWorking)
            
            Button("Test Storage po cofnięciu dostępu") {
                Task {
                    await testRevokedStorageAccess()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isWorking)

            Text(photoStatus)
                .font(.caption)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            if let downloadedImage {
                Image(uiImage: downloadedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 250, maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private func testAccess() async {
        isWorking = true
        defer { isWorking = false }

        guard let lesionID = UUID(
            uuidString: "b09df69a-ae8f-4948-b468-cbe7b1c6e9b4"
        ) else {
            result = "Nieprawidłowy UUID znamienia."
            return
        }

        do {
            let lesions: [SharedLesion] = try await client
                .from("lesions")
                .select("id, name, body_location")
                .eq("id", value: lesionID.uuidString.lowercased())
                .execute()
                .value

            if let lesion = lesions.first {
                result = """
                SUKCES
                Znamię: \(lesion.name)
                Lokalizacja: \(lesion.body_location)
                """
            } else {
                result = "BRAK DOSTĘPU: Nie znaleziono znamienia."
            }

        } catch {
            result = "BŁĄD: \(error.localizedDescription)"
        }
    }
    
    
    private func testPhotoAccess() async {
        isWorking = true
        defer { isWorking = false }

        guard let lesionID = UUID(
            uuidString: "b09df69a-ae8f-4948-b468-cbe7b1c6e9b4"
        ) else {
            photoStatus = "Nieprawidłowy UUID znamienia."
            return
        }

        do {
            // Pobierz historie fotografii udostepnionego znamienia
            let photos = try await photoService.getPhotoHistory(
                for: lesionID
            )

            guard let photo = photos.first else {
                photoStatus = "Nie znaleziono zdjęć znamienia."
                return
            }

            // Pobierz JPG z prywatnego Storage
            let imageData = try await photoService.downloadPhoto(
                storagePath: photo.storagePath
            )

            guard let image = UIImage(data: imageData) else {
                photoStatus = "Nie udało się odczytać JPG."
                return
            }

            downloadedImage = image
            photoStatus = "SUKCES: Dermatolog pobrał zdjęcie."

        } catch {
            photoStatus = "BŁĄD: \(error.localizedDescription)"
        }
    }
    
    private func testRevokedStorageAccess() async {
        isWorking = true
        defer { isWorking = false }

        let path = """
        b6fb5ab0-01cd-44d5-930c-695520990c78/\
        b09df69a-ae8f-4948-b468-cbe7b1c6e9b4/\
        51538ec3-2402-4e63-b8e2-d1edb9fa5dce.jpg
        """

        do {
            _ = try await photoService.downloadPhoto(
                storagePath: path
            )

            photoStatus = "BŁĄD BEZPIECZEŃSTWA: Zdjęcie nadal dostępne!"

        } catch {
            photoStatus = "SUKCES: Storage zablokował dostęp."
        }
    }


}
