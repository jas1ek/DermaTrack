
import SwiftUI

struct AddLesionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lesionService: LesionService

    let existingLesion: Lesion?

    @State private var selectedType: String
    @State private var location: String
    @State private var notes: String

    private let types = [
        "Nie wiem / do oceny",
        "Znamię barwnikowe",
        "Plama",
        "Grudka / guzek",
        "Brodawka",
        "Inna zmiana"
    ]

    init(existingLesion: Lesion? = nil) {
        self.existingLesion = existingLesion

        _selectedType = State(
            initialValue: existingLesion?.name
                ?? "Nie wiem / do oceny"
        )
        _location = State(
            initialValue: existingLesion?.location ?? ""
        )
        _notes = State(
            initialValue: existingLesion?.notes ?? ""
        )
    }

    var body: some View {
        NavigationStack {
            Form {
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

                Section("Lokalizacja") {
                    TextField(
                        "Np. prawe przedramię",
                        text: $location
                    )
                }

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
                        ).isEmpty
                    )
                }
            }
        }
    }

    private var availableTypes: [String] {
        if types.contains(selectedType) {
            return types
        }
        return [selectedType] + types
    }

    private func saveLesion() {
        let trimmedLocation = location.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if var lesion = existingLesion {
            lesion.name = selectedType
            lesion.location = trimmedLocation
            lesion.notes = notes
            lesionService.update(lesion)
        } else {
            let lesion = Lesion(
                name: selectedType,
                location: trimmedLocation,
                notes: notes
            )
            lesionService.add(lesion)
        }

        dismiss()
    }
}

#Preview {
    AddLesionView()
        .environmentObject(LesionService())
}
