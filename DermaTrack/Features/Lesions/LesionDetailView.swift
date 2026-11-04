
import SwiftUI
import PhotosUI
import UIKit

struct LesionDetailView: View {

    let lesionID: UUID

    @EnvironmentObject private var lesionService: LesionService
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showingCamera = false

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isImporting = false

    @State private var showDeleteConfirmation = false
    @State private var photoToDelete: URL?

    @State private var showPhotoError = false
    @State private var photoErrorMessage = ""

    // MARK: - Aktualna zmiana

    private var lesion: Lesion? {
        lesionService.lesions.first {
            $0.id == lesionID
        }
    }

    // MARK: - Historia zdjec

    private var photoURLs: [URL] {
        _ = lesionService.photoVersion
        return lesionService.photoURLs(for: lesionID)
    }

    // MARK: - Widok glowny

    var body: some View {
        Group {
            if let lesion {
                lesionContent(lesion)
            } else {
                ContentUnavailableView(
                    "Nie znaleziono zmiany",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Zmiana mogla zostac usunieta.")
                )
            }
        }
        .navigationTitle("Szczegoly zmiany")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if lesion != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edytuj") {
                        showEdit = true
                    }
                }
            }
        }

        // Edycja istniejacej zmiany
        .sheet(isPresented: $showEdit) {
            if let lesion {
                AddLesionView(existingLesion: lesion)
                    .environmentObject(lesionService)
            }
        }

        // Aparat AVFoundation
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(lesionID: lesionID)
                .environmentObject(lesionService)
        }

        // Import tylko zdjec wybranych przez uzytkownika
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }

            Task {
                await importPhoto(item)
            }
        }

        // Usuwanie calej zmiany
        .confirmationDialog(
            "Usunac zmiane wraz ze wszystkimi zdjeciami?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Usun zmiane", role: .destructive) {
                lesionService.delete(id: lesionID)
                dismiss()
            }
        } message: {
            Text("Tej operacji nie mozna cofnac.")
        }

        // Usuwanie pojedynczego zdjecia
        .confirmationDialog(
            "Usunac wybrane zdjecie?",
            isPresented: Binding(
                get: { photoToDelete != nil },
                set: { if !$0 { photoToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Usun zdjecie", role: .destructive) {
                if let url = photoToDelete {
                    lesionService.deletePhoto(
                        at: url,
                        for: lesionID
                    )
                }
                photoToDelete = nil
            }

            Button("Anuluj", role: .cancel) {
                photoToDelete = nil
            }
        } message: {
            Text("Fotografia zostanie usunieta z lokalnej dokumentacji.")
        }

        // Bledy importowania
        .alert(
            "Nie udalo sie dodac zdjecia",
            isPresented: $showPhotoError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoErrorMessage)
        }
    }

    // MARK: - Zawartosc ekranu

    private func lesionContent(_ lesion: Lesion) -> some View {
        List {

            Section("Informacje") {
                LabeledContent(
                    "Rodzaj zmiany",
                    value: lesion.name
                )

                LabeledContent(
                    "Lokalizacja",
                    value: lesion.location
                )

                LabeledContent(
                    "Data dodania",
                    value: lesion.createdAt.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
            }

            Section("Notatki") {
                if lesion.notes.isEmpty {
                    Text("Brak notatek")
                        .foregroundStyle(.secondary)
                } else {
                    Text(lesion.notes)
                }
            }

            Section("Historia zdjec") {

                // Fotografowanie aparatem
                Button {
                    showingCamera = true
                } label: {
                    Label(
                        "Zrob zdjecie aparatem",
                        systemImage: "camera.fill"
                    )
                }

                // Import przez PhotosPicker
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    preferredItemEncoding: .automatic
                ) {
                    Label(
                        "Dodaj zdjecie z galerii",
                        systemImage: "photo.on.rectangle"
                    )
                }
                .disabled(isImporting)

                if isImporting {
                    HStack {
                        ProgressView()
                        Text("Importowanie fotografii...")
                            .foregroundStyle(.secondary)
                    }
                }
                if photoURLs.count >= 2 {
                    NavigationLink {
                        PhotoComparisonView(lesionID: lesionID)
                            .environmentObject(lesionService)
                    } label: {
                        Label(
                            "Porównaj zdjęcia",
                            systemImage: "rectangle.split.2x1"
                        )
                    }
                }

                if photoURLs.isEmpty {
                    ContentUnavailableView(
                        "Brak fotografii",
                        systemImage: "photo",
                        description: Text(
                            "Dodaj pierwsze zdjecie, aby rozpoczac historie obserwacji."
                        )
                    )
                } else {
                    ForEach(photoURLs, id: \.self) { url in
                        photoRow(url)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        "Usun zmiane",
                        systemImage: "trash"
                    )
                }
            }
        }
    }

    // MARK: - Element historii zdjec

    private func photoRow(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 300)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
            } else {
                Label(
                    "Nie mozna odczytac zdjecia",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.secondary)
            }

            HStack {
                if let date = creationDate(for: url) {
                    Text(
                        date.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text("Fotografia")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    photoToDelete = url
                } label: {
                    Label("Usun", systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Odczyt daty pliku

    private func creationDate(for url: URL) -> Date? {
        let values = try? url.resourceValues(
            forKeys: [.creationDateKey]
        )

        return values?.creationDate
    }

    // MARK: - Import przez PhotosPicker

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem) async {
        guard !isImporting else { return }

        isImporting = true

        defer {
            isImporting = false
            selectedPhoto = nil
        }

        do {
            guard let data = try await item.loadTransferable(
                type: Data.self
            ) else {
                photoErrorMessage =
                    "Nie udalo sie odczytac wybranej fotografii."
                showPhotoError = true
                return
            }

            try lesionService.addPhoto(
                data,
                to: lesionID
            )

        } catch {
            photoErrorMessage =
                "Blad importu: \(error.localizedDescription)"
            showPhotoError = true
        }
    }
}

