
import SwiftUI
import PhotosUI
import UIKit

struct LesionDetailView: View {
    let lesionID: UUID

    @EnvironmentObject private var lesionService: LesionService
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showDelete = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoError = false
    @State private var isLoadingPhoto = false

    private var lesion: Lesion? {
        lesionService.lesions.first {
            $0.id == lesionID
        }
    }

    var body: some View {
        Group {
            if let lesion {
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

                    Section("Historia zdjęć") {
                        let photos = lesionService.photoURLs(
                            for: lesionID
                        )

                        if photos.isEmpty {
                            Text("Nie dodano jeszcze zdjęć.")
                                .foregroundStyle(.secondary)
                        }

                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(photos, id: \.self) { url in
                                    if let image = UIImage(
                                        contentsOfFile: url.path
                                    ) {
                                        VStack {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(
                                                    width: 130,
                                                    height: 130
                                                )
                                                .clipped()
                                                .clipShape(
                                                    RoundedRectangle(
                                                        cornerRadius: 12
                                                    )
                                                )

                                            Button("Usuń zdjęcie", role: .destructive) {
                                                lesionService.deletePhoto(
                                                    at: url,
                                                    for: lesionID
                                                )
                                            }
                                            .font(.caption)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            Label(
                                "Dodaj kolejne zdjęcie",
                                systemImage: "plus.circle"
                            )
                        }
                        .disabled(isLoadingPhoto)

                        if isLoadingPhoto {
                            ProgressView("Dodawanie zdjęcia...")
                        }
                    }

                    Section("Notatki") {
                        Text(
                            lesion.notes.isEmpty
                                ? "Brak notatek"
                                : lesion.notes
                        )
                    }

                    Section {
                        Button("Usuń zmianę", role: .destructive) {
                            showDelete = true
                        }
                    }
                }
                .navigationTitle(lesion.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edytuj") {
                            showEdit = true
                        }
                    }
                }
                .sheet(isPresented: $showEdit) {
                    AddLesionView(existingLesion: lesion)
                }
            } else {
                ContentUnavailableView(
                    "Nie znaleziono zmiany",
                    systemImage: "exclamationmark.circle"
                )
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }

            Task {
                isLoadingPhoto = true
                defer {
                    isLoadingPhoto = false
                    selectedPhoto = nil
                }

                do {
                    guard let data = try await newItem.loadTransferable(
                        type: Data.self
                    ) else {
                        showPhotoError = true
                        return
                    }

                    try lesionService.addPhoto(
                        data,
                        to: lesionID
                    )
                } catch {
                    showPhotoError = true
                }
            }
        }
        .confirmationDialog(
            "Usunąć tę zmianę wraz ze zdjęciami?",
            isPresented: $showDelete,
            titleVisibility: .visible
        ) {
            Button("Usuń zmianę", role: .destructive) {
                lesionService.delete(id: lesionID)
                dismiss()
            }
        }
        .alert(
            "Nie udało się dodać zdjęcia",
            isPresented: $showPhotoError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Sprawdź format zdjęcia i spróbuj ponownie.")
        }
    }
}
