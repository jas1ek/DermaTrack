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
}

