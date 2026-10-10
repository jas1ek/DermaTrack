
import SwiftUI

struct BodyMapView: View {
    @EnvironmentObject private var lesionService: LesionService

    @State private var selectedSide = BodySide.front
    @State private var selectedArea: String?
    @State private var showingAddLesion = false

    enum BodySide: String, CaseIterable {
        case front = "Przód"
        case back = "Tył"
    }

    private var areas: [String] {
        switch selectedSide {
        case .front:
            return [
                "Twarz",
                "Szyja",
                "Klatka piersiowa",
                "Brzuch",
                "Lewe ramię",
                "Prawe ramię",
                "Lewe przedramię",
                "Prawe przedramię",
                "Lewa dłoń",
                "Prawa dłoń",
                "Lewe udo",
                "Prawe udo",
                "Lewe podudzie",
                "Prawe podudzie",
                "Lewa stopa",
                "Prawa stopa"
            ]

        case .back:
            return [
                "Tył głowy",
                "Kark",
                "Górna część pleców",
                "Dolna część pleców",
                "Lewy bark",
                "Prawy bark",
                "Lewe ramię - tył",
                "Prawe ramię - tył",
                "Lewy pośladek",
                "Prawy pośladek",
                "Lewe udo - tył",
                "Prawe udo - tył",
                "Lewa łydka",
                "Prawa łydka"
            ]
        }
    }

    private var matchingLesions: [Lesion] {
        guard let selectedArea else {
            return []
        }

        return lesionService.lesions.filter {
            $0.location == selectedArea
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Widok ciała", selection: $selectedSide) {
                        ForEach(BodySide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)

                    Image(systemName: "figure.stand")
                        .font(.system(size: 100))
                        .foregroundStyle(.teal)
                        .frame(height: 150)
                        .accessibilityHidden(true)

                    Text("Wybierz obszar ciała")
                        .font(.headline)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 12
                    ) {
                        ForEach(areas, id: \.self) { area in
                            Button {
                                selectedArea = area
                            } label: {
                                Text(area)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 55)
                                    .padding(.horizontal, 6)
                                    .background(
                                        selectedArea == area
                                            ? Color.teal.opacity(0.2)
                                            : Color.gray.opacity(0.1)
                                    )
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 12
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let selectedArea {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(selectedArea)
                                .font(.title3.bold())

                            if matchingLesions.isEmpty {
                                Text("Brak zapisanych zmian w tym obszarze.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(matchingLesions) { lesion in
                                    NavigationLink {
                                        LesionDetailView(lesionID: lesion.id)
                                    } label: {
                                        HStack {
                                            Text(lesion.name)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding()
                                        .background(.regularMaterial)
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 12
                                            )
                                        )
                                    }
                                }
                            }

                            Button {
                                showingAddLesion = true
                            } label: {
                                Label(
                                    "Dodaj zmianę w tym miejscu",
                                    systemImage: "plus.circle.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                    }
                }
                .padding()
            }
            .navigationTitle("Mapa ciała")
            .onChange(of: selectedSide) { _, _ in
                selectedArea = nil
            }
            .sheet(isPresented: $showingAddLesion) {
                AddLesionView(
                    initialLocation: selectedArea ?? ""
                )
            }
        }
    }
}

#Preview {
    BodyMapView()
        .environmentObject(LesionService())
}
