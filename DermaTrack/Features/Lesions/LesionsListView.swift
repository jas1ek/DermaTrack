
import SwiftUI

struct LesionsListView: View {
    @EnvironmentObject private var lesionService: LesionService

    @State private var showingAddLesion = false
    @State private var editMode: EditMode = .inactive
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if lesionService.isLoading && lesionService.lesions.isEmpty {
                    ProgressView("Pobieranie znamion...")
                } else if lesionService.lesions.isEmpty {
                    ContentUnavailableView(
                        "Brak zmian",
                        systemImage: "plus.circle",
                        description: Text(
                            "Dodaj pierwszą zmianę przyciskiem +."
                        )
                    )
                } else {
                    List {
                        ForEach(lesionService.lesions) { lesion in
                            NavigationLink {
                                LesionDetailView(lesionID: lesion.id)
                            } label: {
                                VStack(
                                    alignment: .leading,
                                    spacing: 5
                                ) {
                                    Text(lesion.name)
                                        .font(.headline)

                                    Text(lesion.location)
                                        .foregroundStyle(.secondary)

                                    Text(
                                        lesion.createdAt.formatted(
                                            date: .abbreviated,
                                            time: .omitted
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .onDelete { offsets in
                            let ids = offsets.compactMap { index in
                                lesionService.lesions.indices.contains(index)
                                ? lesionService.lesions[index].id : nil
                            }
                            Task {
                                for id in ids {
                                    do { try await lesionService.delete(id: id) }
                                    catch {
                                        deleteErrorMessage = error.localizedDescription
                                        showDeleteError = true
                                        break
                                    }
                                }
                            }
                        }
                    }
                    .environment(\.editMode, $editMode)
                }
            }
            .navigationTitle("Moje zmiany")
            .refreshable { await lesionService.refresh() }
            .alert("Nie udało się usunąć znamienia", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: { Text(deleteErrorMessage) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !lesionService.lesions.isEmpty {
                        Button(
                            editMode == .active
                                ? "Gotowe"
                                : "Edytuj"
                        ) {
                            editMode = editMode == .active
                                ? .inactive
                                : .active
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddLesion = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLesion) {
                AddLesionView()
            }
        }
    }
}

#Preview {
    LesionsListView()
        .environmentObject(LesionService())
}
