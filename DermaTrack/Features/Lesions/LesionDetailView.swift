
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

    @State private var showDeleteConfirmation = false
    @State private var showPhotoError = false
    @State private var photoErrorMessage = ""
    @State private var isImporting = false

    // MARK: - Aktualna zmiana

    private var lesion: Lesion? {
        lesionService.lesions.first {
            $0.id == lesionID
        }
    }

    // MARK: - Zdjęcia zapisane na urządzeniu

    private var photoURLs: [URL] {
        // Obserwujemy aktualizacje historii fotografii.
        _ = lesionService.photoVersion

        return lesionService.photoURLs(for: lesionID)
    }

    // MARK: - Widok główny

    var body: some View {
        Group {
            if let lesion {
                lesionContent(lesion)
            } else {
                ContentUnavailableView(
                    "Nie znaleziono zmiany",
                    systemImage: "exclamationmark.triangle",
                    description: Text(
                        "Zmiana mogła zostać usunięta."
                    )
                )
            }
        }
        .navigationTitle("Szczegóły zmiany")
        .navigationBarTitleDisplayMode(.inline)

        // Przycisk edycji
        .toolbar {
            if lesion != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edytuj") {
                        showEdit = true
                    }
                }
            }
        }

        // Formularz edycji
        .sheet(isPresented: $showEdit) {
            if let lesion {
                AddLesionView(existingLesion: lesion)
                    .environmentObject(lesionService)
            }
        }

        // Pełnoekranowy aparat
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(lesionID: lesionID)
                .environmentObject(lesionService)
        }

        // Import zdjęcia z galerii
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }

            Task {
                isImporting = true
                defer {
                    isImporting = false
                    selectedPhoto = nil
                }

                do {
                    guard let data =
                        try await newItem.loadTransferable(
                            type: Data.self
                        ) else {
                        photoErrorMessage =
                            "Nie udało się odczytać zdjęcia."
                        showPhotoError = true
                        return
                    }

                    try lesionService.addPhoto(
                        data,
                        to: lesionID
                    )

                } catch {
                    photoErrorMessage =
                        "Nie udało się dodać fotografii: \(error.localizedDescription)"
                    showPhotoError = true
                }
            }
        }

        // Potwierdzenie usunięcia zmiany
        .confirmationDialog(
            "Usunąć zmianę i wszystkie jej zdjęcia?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Usuń zmianę", role: .destructive) {
                lesionService.delete(id: lesionID)
                dismiss()
            }

            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Tej operacji nie można cofnąć.")
        }

        // Komunikat błędu fotografii
        .alert(
            "Błąd zdjęcia",
            isPresented: $showPhotoError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoErrorMessage)
        }
    }

    // MARK: - Zawartość ekranu

    private func lesionContent(_ lesion: Lesion) -> some View {
        List {

            // MARK: Informacje

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

            // MARK: Notatki

            Section("Notatki") {
                if lesion.notes.isEmpty {
                    Text("Brak notatek")
                        .foregroundStyle(.secondary)
                } else {
                    Text(lesion.notes)
                }
            }

            // MARK: Dokumentacja fotograficzna

            Section("Historia zdjęć") {

                Button {
                    showingCamera = true
                } label: {
                    Label(
                        "Zrób zdjęcie aparatem",
                        systemImage: "camera.fill"
                    )
                }

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    Label(
                        "Dodaj zdjęcie z galerii",
                        systemImage: "photo.on.rectangle"
                    )
                }
                .disabled(isImporting)

                if isImporting {
                    ProgressView("Importowanie zdjęcia...")
                }

                if photoURLs.isEmpty {
                    Text("Nie dodano jeszcze zdjęć.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(photoURLs, id: \.self) { url in
                        photoRow(url)
                    }
                }
            }

            // MARK: Usuwanie całej zmiany

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        "Usuń zmianę",
                        systemImage: "trash"
                    )
                }
            }
        }
    }

    // MARK: - Jeden element historii zdjęć

    private func photoRow(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            if let image = UIImage(
                contentsOfFile: url.path
            ) {
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
                    "Nie można otworzyć zdjęcia",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.secondary)
            }

            HStack {
                Text(url.lastPathComponent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(role: .destructive) {
                    lesionService.deletePhoto(
                        at: url,
                        for: lesionID
                    )
                } label: {
                    Label(
                        "Usuń",
                        systemImage: "trash"
                    )
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
    }
}
