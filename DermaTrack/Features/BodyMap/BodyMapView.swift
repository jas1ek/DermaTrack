
import SwiftUI

struct BodyMapView: View {
    @EnvironmentObject private var lesionService: LesionService

    @State private var selectedSide = BodySide.front
    @State private var selectedPosition: CGPoint?
    @State private var showingAddLesion = false

    enum BodySide: String, CaseIterable {
        case front = "front"
        case back = "back"

        var title: String {
            self == .front ? "Przód" : "Tył"
        }
    }

    private var mappedLesions: [Lesion] {
        lesionService.lesions.filter {
            $0.mapSide == selectedSide.rawValue &&
            $0.mapX != nil &&
            $0.mapY != nil
        }
    }

    private var unmappedLesions: [Lesion] {
        lesionService.lesions.filter {
            $0.mapX == nil ||
            $0.mapY == nil ||
            $0.mapSide == nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Widok ciała", selection: $selectedSide) {
                        ForEach(BodySide.allCases, id: \.self) { side in
                            Text(side.title).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedSide) { _, _ in
                        selectedPosition = nil
                    }

                    Text("Dotknij miejsca na sylwetce")
                        .font(.headline)

                    Text("Kolorowe punkty oznaczają zapisane zmiany.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    bodyDiagram

                    if selectedPosition != nil {
                        Button {
                            showingAddLesion = true
                        } label: {
                            Label(
                                "Dodaj zmianę w wybranym miejscu",
                                systemImage: "plus.circle.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if !unmappedLesions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Zmiany bez punktu na mapie")
                                .font(.headline)

                            ForEach(unmappedLesions) { lesion in
                                NavigationLink {
                                    LesionDetailView(
                                        lesionID: lesion.id
                                    )
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(lesion.name)
                                            Text(lesion.location)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Mapa ciała")
            .sheet(isPresented: $showingAddLesion) {
                if let position = selectedPosition {
                    AddLesionView(
                        initialLocation: suggestedLocation(
                            for: position
                        ),
                        initialMapSide: selectedSide.rawValue,
                        initialMapX: Double(position.x),
                        initialMapY: Double(position.y)
                    )
                }
            }
        }
    }

    private var bodyDiagram: some View {
        GeometryReader { geometry in
            ZStack {
                BodySilhouette()
                    .fill(Color.teal.opacity(0.25))
                    .overlay {
                        BodySilhouette()
                            .stroke(
                                Color.teal,
                                lineWidth: 2
                            )
                    }
                    .contentShape(BodySilhouette())
                    .onTapGesture { location in
                        let bounds = CGRect(
                            origin: .zero,
                            size: geometry.size
                        )

                        let silhouette = BodySilhouette()
                            .path(in: bounds)

                        guard silhouette.contains(location) else {
                            return
                        }

                        selectedPosition = CGPoint(
                            x: location.x / geometry.size.width,
                            y: location.y / geometry.size.height
                        )
                    }

                ForEach(mappedLesions) { lesion in
                    if let x = lesion.mapX,
                       let y = lesion.mapY {
                        NavigationLink {
                            LesionDetailView(lesionID: lesion.id)
                        } label: {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 20, height: 20)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            .white,
                                            lineWidth: 2
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "\(lesion.name), \(lesion.location)"
                        )
                        .position(
                            x: geometry.size.width * x,
                            y: geometry.size.height * y
                        )
                    }
                }

                if let position = selectedPosition {
                    Circle()
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(
                                lineWidth: 3,
                                dash: [5, 3]
                            )
                        )
                        .frame(width: 30, height: 30)
                        .position(
                            x: geometry.size.width * position.x,
                            y: geometry.size.height * position.y
                        )
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(width: 260, height: 420)
        .frame(maxWidth: .infinity)
    }

    private func suggestedLocation(
        for position: CGPoint
    ) -> String {
        let prefix = selectedSide.title

        if position.y < 0.2 {
            return "\(prefix) - głowa"
        }

        if position.x < 0.32 {
            return "\(prefix) - lewa strona / ramię"
        }

        if position.x > 0.68 {
            return "\(prefix) - prawa strona / ramię"
        }

        if position.y < 0.5 {
            return selectedSide == .front
                ? "Klatka piersiowa / brzuch"
                : "Plecy"
        }

        if position.y < 0.6 {
            return "Okolica bioder"
        }

        return position.x < 0.5
            ? "Lewa noga"
            : "Prawa noga"
    }
}

#Preview {
    BodyMapView()
        .environmentObject(LesionService())
}
