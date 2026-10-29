//
//  StorageTestView.swift
//  DermaTrack
//
//  Created by Julia Marek on 29/10/2026.
//


import SwiftUI
import UIKit
import Supabase

struct StorageTestView: View {

    @State private var filePath = ""
    @State private var status = "Nie wykonano testu"
    @State private var isWorking = false

    private let client = SupabaseManager.shared.client
    private let bucket = "lesion-photos"

    var body: some View {
        VStack(spacing: 12) {
            Text("Test bezpieczeństwa Storage")
                .font(.headline)

            TextField("Ścieżka pliku", text: $filePath)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("1. Wyślij zdjęcie testowe") {
                Task { await uploadTest() }
            }

            Button("2. Pobierz zdjęcie") {
                Task { await downloadTest() }
            }

            Text(status)
                .font(.caption)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            if isWorking {
                ProgressView()
            }
        }
        .buttonStyle(.bordered)
        .disabled(isWorking)
        .padding()
    }

    private func uploadTest() async {
        isWorking = true
        defer { isWorking = false }

        do {
            let user = try await client.auth.user()
            let image = UIGraphicsImageRenderer(
                size: CGSize(width: 100, height: 100)
            ).image { context in
                UIColor.systemBlue.setFill()
                context.fill(
                    CGRect(x: 0, y: 0, width: 100, height: 100)
                )
            }

            guard let data = image.jpegData(
                compressionQuality: 0.7
            ) else {
                status = "Błąd generowania JPG"
                return
            }

            let path = "\(user.id.uuidString.lowercased())/test/\(UUID().uuidString.lowercased()).jpg"

            try await client.storage
                .from(bucket)
                .upload(
                    path,
                    data: data,
                    options: FileOptions(
                        contentType: "image/jpeg"
                    )
                )

            filePath = path
            status = "UPLOAD OK\n\(path)"

        } catch {
            status = "UPLOAD ODRZUCONY:\n\(error.localizedDescription)"
        }
    }

    private func downloadTest() async {
        isWorking = true
        defer { isWorking = false }

        do {
            let data = try await client.storage
                .from(bucket)
                .download(path: filePath)

            status = "DOWNLOAD OK: \(data.count) bajtów"

        } catch {
            status = "DOWNLOAD ODRZUCONY:\n\(error.localizedDescription)"
        }
    }
}

