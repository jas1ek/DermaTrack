//
//  AddLesionTestView.swift
//  DermaTrack
//
//  Created by Julia Marek on 04/11/2026.
//


import SwiftUI
import UIKit

struct AddLesionTestView: View {

    @State private var name = "Znamię testowe"
    @State private var bodyLocation = "Lewe ramię"
    @State private var description = "Test Z3"

    @State private var status = ""
    @State private var isWorking = false
    
    @State private var photoHistory: [LesionPhotoRecord] = []
    @State private var historyStatus = ""
    
    @State private var downloadedImage: UIImage?

    private let lesionService = LesionBackendService()
    private let photoService = PhotoStorageService()

    var body: some View {
        VStack(spacing: 12) {

            Text("Dodawanie znamienia i zdjęcia")
                .font(.headline)

            TextField("Nazwa znamienia", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("Lokalizacja", text: $bodyLocation)
                .textFieldStyle(.roundedBorder)

            TextField("Opis", text: $description)
                .textFieldStyle(.roundedBorder)

            Button("Dodaj znamię ze zdjęciem") {
                Task {
                    await addLesionWithPhoto()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking)
            
            Button("Pobierz historię zdjęć") {
                Task {
                    await loadPhotoHistory()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isWorking)

            Text(historyStatus)
                .font(.caption)
                .multilineTextAlignment(.center)

            
            ForEach(photoHistory) { photo in
                VStack(alignment: .leading, spacing: 8) {

                    Text("Zdjęcie: \(photo.id.uuidString)")
                    Text("Data: \(photo.capturedAt)")
                    Text("Ścieżka: \(photo.storagePath)")

                    Button("Pobierz i wyświetl zdjęcie") {
                        Task {
                            await downloadAndShowPhoto(
                                path: photo.storagePath
                            )
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isWorking)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Podgląd pobranego zdjęcia
            if let downloadedImage {
                Image(uiImage: downloadedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 250, maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }


            if isWorking {
                ProgressView()
            }

            Text(status)
                .font(.caption)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .padding()
    }

    private func addLesionWithPhoto() async {
        isWorking = true
        defer { isWorking = false }

        do {
            let lesionID = try await lesionService
                .createLesion(
                    name: name,
                    bodyLocation: bodyLocation,
                    description: description
                )

            status = "Znamię zapisane. Trwa zapis zdjęcia..."

            let image = UIGraphicsImageRenderer(
                size: CGSize(width: 100, height: 100)
            ).image { context in
                UIColor.systemGreen.setFill()
                context.fill(
                    CGRect(x: 0, y: 0, width: 100, height: 100)
                )
            }

            guard let imageData = image.jpegData(
                compressionQuality: 0.8
            ) else {
                status = "Nie udało się utworzyć zdjęcia"
                return
            }

            let path = try await photoService.addPhoto(
                to: lesionID,
                imageData: imageData
            )

            status = """
            SUKCES
            Znamię: \(lesionID)
            Zdjęcie: \(path)
            """

        } catch {
            status = "BŁĄD: \(error.localizedDescription)"
        }
    }
    
    private func loadPhotoHistory() async {
        isWorking = true
        defer { isWorking = false }

        do {
            // UUID znamienia utworzonego w poprzednim teście
            let lesionID = UUID(
                uuidString: "b09df69a-ae8f-4948-b468-cbe7b1c6e9b4"
            )!

            let photos = try await photoService.getPhotoHistory(
                for: lesionID
            )

            photoHistory = photos
            historyStatus = "Znaleziono zdjęć: \(photos.count)"

        } catch {
            historyStatus = "Błąd: \(error.localizedDescription)"
        }
    }
    
    
    private func downloadAndShowPhoto(
        path: String
    ) async {

        isWorking = true
        defer { isWorking = false }

        do {
            let imageData = try await photoService.downloadPhoto(
                storagePath: path
            )

            guard let image = UIImage(data: imageData) else {
                historyStatus = "Nie udało się odczytać zdjęcia."
                return
            }

            downloadedImage = image
            historyStatus = "Zdjęcie pobrane poprawnie."

        } catch {
            historyStatus = "Błąd pobierania: \(error.localizedDescription)"
        }
    }

}

