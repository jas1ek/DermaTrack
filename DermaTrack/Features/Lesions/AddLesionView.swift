
import SwiftUI
import PhotosUI
import UIKit

struct AddLesionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lesionService: LesionService

    let existingLesion: Lesion?
    let initialMapSide: String?
    let initialMapX: Double?
    let initialMapY: Double?

    @State private var selectedType: String
    @State private var location: String
    @State private var notes: String

    // Zdjęcia przygotowane do zapisania
    @State private var stagedPhotos: [Data] = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isImporting = false
    @State private var showSaveError = false
    @State private var showImportError = false

    // Chroni przed dodaniem drugiego wpisu po błędzie zapisu
    @State private var createdLesionID: UUID?

    private let types = [
        "Nie wiem / do oceny",
        "Znamię barwnikowe",
        "Plama",
        "Grudka / guzek",
        "Brodawka",
        "Inna zmiana"
    ]

    init(
        existingLesion: Lesion? = nil,
        initialLocation: String = "",
        initialMapSide: String? = nil,
        initialMapX: Double? = nil,
        initialMapY: Double? = nil
    ) {
        self.existingLesion = existingLesion
        self.initialMapSide = initialMapSide
        self.initialMapX = initialMapX
        self.initialMapY = initialMapY

        _selectedType = State(
            initialValue: existingLesion?.name
                ?? "Nie wiem / do oceny"
        )

        _location = State(
            initialValue: existingLesion?.location
                ?? initialLocation
        )

        _notes = State(
            initialValue: existingLesion?.notes ?? ""
        )
    }

    private var availableTypes: [String] {
        if types.contains(selectedType) {
            return types
        }
        return [selectedType] + types
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Rodzaj zmiany

                Section("Rodzaj zmiany") {
                    Picker("Rodzaj", selection: $selectedType) {
                        ForEach(availableTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }

                    Text("Wybór ma charakter opisowy, nie jest diagnozą.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Lokalizacja

                Section("Lokalizacja") {
                    TextField(
                        "Np. prawe przedramię",
                        text: $location
                    )
                }

                // MARK: - Zdjęcia

                Section("Dokumentacja fotograficzna") {

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
                        ProgressView("Wczytywanie zdjęcia...")
                    }

                    if stagedPhotos.isEmpty {
                        Text("Nie wybrano nowych zdjęć.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(
                            "Nowe zdjęcia: \(stagedPhotos.count)"
                        )
                        .font(.subheadline.bold())

                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(
                                    stagedPhotos.indices,
                                    id: \.self
                                ) { index in

                                    if let image = UIImage(
                                        data: stagedPhotos[index]
                                    ) {
                                        VStack(spacing: 8) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(
                                                    width: 110,
                                                    height: 110
                                                )
                                                .clipped()
                                                .clipShape(
                                                    RoundedRectangle(
                                                        cornerRadius: 10
                                                    )
                                                )

                                            Button(
                                                "Usuń",
                                                role: .destructive
                                            ) {
                                                stagedPhotos.remove(
                                                    at: index
                                                )
                                            }
                                            .font(.caption)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    if existingLesion != nil {
                        Text(
                            "Wcześniej zapisane zdjęcia pozostają w historii zmiany."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Notatki

                Section("Notatki") {
                    TextField(
                        "Opis i obserwacje",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle(
                existingLesion == nil
                    ? "Nowa zmiana"
                    : "Edytuj zmianę"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        saveLesion()
                    }
                    .disabled(
                        location.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || isImporting
                    )
                }
            }
            .sheet(isPresented: $showingCamera) {
                DraftCameraView { data in
                    stagedPhotos.append(data)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }

                Task {
                    isImporting = true
                    defer {
                        isImporting = false
                        selectedPhoto = nil
                    }

                    do {
                        guard let data = try await item.loadTransferable(
                            type: Data.self
                        ),
                        UIImage(data: data) != nil else {
                            showImportError = true
                            return
                        }

                        stagedPhotos.append(data)
                    } catch {
                        showImportError = true
                    }
                }
            }
            .alert(
                "Nie udało się wczytać zdjęcia",
                isPresented: $showImportError
            ) {
                Button("OK", role: .cancel) {}
            }
            .alert(
                "Nie udało się zapisać wszystkich zdjęć",
                isPresented: $showSaveError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "Wpis został zachowany lokalnie. Spróbuj ponownie zapisać pozostałe zdjęcia."
                )
            }
        }
    }

    // MARK: - Zapis zmiany i zdjęć

    private func saveLesion() {
        let trimmedLocation = location.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let lesionID: UUID

        if var lesion = existingLesion {
            lesion.name = selectedType
            lesion.location = trimmedLocation
            lesion.notes = notes

            lesionService.update(lesion)
            lesionID = lesion.id

        } else if let previousID = createdLesionID {
            lesionID = previousID

            if let oldLesion = lesionService.lesions.first(
                where: { $0.id == previousID }
            ) {
                var updated = oldLesion
                updated.name = selectedType
                updated.location = trimmedLocation
                updated.notes = notes
                lesionService.update(updated)
            }

        } else {
            let newLesion = Lesion(
                name: selectedType,
                location: trimmedLocation,
                notes: notes,
                mapSide: initialMapSide,
                mapX: initialMapX,
                mapY: initialMapY
            )

            lesionService.add(newLesion)
            lesionID = newLesion.id
            createdLesionID = lesionID
        }

        // Zapisuj zdjęcia pojedynczo.
        // Usuń z kolejki dopiero po udanym zapisie.
        while !stagedPhotos.isEmpty {
            do {
                try lesionService.addPhoto(
                    stagedPhotos[0],
                    to: lesionID
                )

                stagedPhotos.removeFirst()
            } catch {
                showSaveError = true
                return
            }
        }

        dismiss()
    }
}

#Preview {
    AddLesionView()
        .environmentObject(LesionService())
}
