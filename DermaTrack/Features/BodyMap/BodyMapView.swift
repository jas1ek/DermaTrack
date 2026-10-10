
import SwiftUI

struct BodyMapView: View {
    @EnvironmentObject private var lesionService: LesionService

    @AppStorage("bodySilhouetteStyle")
    private var silhouetteStyle = BodySilhouetteStyle.male.rawValue

    @State private var selectedSide = BodySide.front
    @State private var mapMode = MapMode.browse
    @State private var showMarkers = true

    @State private var selectedPosition: CGPoint?
    @State private var showingAddLesion = false

    // Powiększenie mapy
    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1

    // Przesunięcie mapy
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero

    private let mapWidth: CGFloat = 260
    private let mapHeight: CGFloat = 420

    enum BodySide: String, CaseIterable {
        case front = "front"
        case back = "back"

        var title: String {
            self == .front ? "Przód" : "Tył"
        }
    }

    enum MapMode: String, CaseIterable {
        case browse = "Przeglądanie"
        case add = "Dodawanie"
    }

    private var currentStyle: BodySilhouetteStyle {
        BodySilhouetteStyle(rawValue: silhouetteStyle) ?? .male
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
            $0.mapSide == nil ||
            $0.mapX == nil ||
            $0.mapY == nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    Picker("Widok ciała", selection: $selectedSide) {
                        ForEach(BodySide.allCases, id: \.self) { side in
                            Text(side.title).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Tryb mapy", selection: $mapMode) {
                        ForEach(MapMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if mapMode == .browse {
                        Toggle(
                            "Pokaż oznaczenia",
                            isOn: $showMarkers
                        )
                    }

                    Text(
                        mapMode == .add
                            ? "Dotknij sylwetki, aby wskazać nową zmianę."
                            : "Dotknij punktu, aby otworzyć szczegóły."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                    zoomControls

                    bodyDiagram

                    Text("Powiększ dwoma palcami i przesuń mapę.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if mapMode == .add,
                       selectedPosition != nil {

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

                        Button("Wybierz inne miejsce") {
                            selectedPosition = nil
                        }
                    }

                    if !unmappedLesions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Zmiany bez punktu na mapie")
                                .font(.headline)

                            ForEach(unmappedLesions) { lesion in
                                NavigationLink {
                                    LesionDetailView(lesionID: lesion.id)
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
            .onChange(of: selectedSide) { _, _ in
                selectedPosition = nil
                resetZoom()
            }
            .onChange(of: mapMode) { _, _ in
                selectedPosition = nil
            }
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

    // MARK: - Przyciski powiększania

    private var zoomControls: some View {
        HStack(spacing: 16) {

            Button {
                changeZoom(by: -0.5)
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .disabled(zoom <= 1)

            Text("\(zoom, specifier: "%.1f")×")
                .monospacedDigit()
                .frame(minWidth: 45)

            Button {
                changeZoom(by: 0.5)
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .disabled(zoom >= 4)

            Spacer()

            Button("Reset") {
                resetZoom()
            }
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Mapa

    private var bodyDiagram: some View {
        ZStack {
            Color.gray.opacity(0.06)

            diagramContent
                .frame(width: mapWidth, height: mapHeight)
                .scaleEffect(zoom)
                .offset(panOffset)
        }
        .frame(width: mapWidth + 30, height: mapHeight + 20)
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(magnificationGesture)
        .simultaneousGesture(panningGesture)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
    }

    private var diagramContent: some View {
        GeometryReader { geometry in
            ZStack {
                BodySilhouette(style: currentStyle)
                    .fill(Color.teal.opacity(0.3))
                    .overlay {
                        BodySilhouette(style: currentStyle)
                            .stroke(Color.teal, lineWidth: 2)
                    }
                    .contentShape(
                        BodySilhouette(style: currentStyle)
                    )
                    .onTapGesture { location in
                        guard mapMode == .add else {
                            return
                        }

                        let bounds = CGRect(
                            origin: .zero,
                            size: geometry.size
                        )

                        let shape = BodySilhouette(
                            style: currentStyle
                        ).path(in: bounds)

                        guard shape.contains(location) else {
                            return
                        }

                        // Pozycja lokalna, niezależna od powiększenia
                        selectedPosition = CGPoint(
                            x: location.x / geometry.size.width,
                            y: location.y / geometry.size.height
                        )
                    }

                if mapMode == .browse && showMarkers {
                    ForEach(mappedLesions) { lesion in
                        if let x = lesion.mapX,
                           let y = lesion.mapY {
                            NavigationLink {
                                LesionDetailView(
                                    lesionID: lesion.id
                                )
                            } label: {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 14, height: 14)
                                    .overlay {
                                        Circle()
                                            .stroke(.white, lineWidth: 2)
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
                }

                if mapMode == .add,
                   let position = selectedPosition {

                    Circle()
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(
                                lineWidth: 2.5,
                                dash: [4, 3]
                            )
                        )
                        .frame(width: 22, height: 22)
                        .position(
                            x: geometry.size.width * position.x,
                            y: geometry.size.height * position.y
                        )
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Gesty

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoom = min(
                    max(lastZoom * value, 1),
                    4
                )
            }
            .onEnded { _ in
                lastZoom = zoom
                clampPan()
            }
    }

    private var panningGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard zoom > 1 else {
                    return
                }

                panOffset = CGSize(
                    width: lastPanOffset.width
                        + value.translation.width,
                    height: lastPanOffset.height
                        + value.translation.height
                )

                clampPan()
            }
            .onEnded { _ in
                lastPanOffset = panOffset
            }
    }

    // MARK: - Funkcje zoom

    private func changeZoom(by amount: CGFloat) {
        zoom = min(max(zoom + amount, 1), 4)
        lastZoom = zoom
        clampPan()
        lastPanOffset = panOffset
    }

    private func resetZoom() {
        zoom = 1
        lastZoom = 1
        panOffset = .zero
        lastPanOffset = .zero
    }

    private func clampPan() {
        let viewportWidth = mapWidth + 30
        let viewportHeight = mapHeight + 20

        let maxX = max(
            0,
            (mapWidth * zoom - viewportWidth) / 2
        )

        let maxY = max(
            0,
            (mapHeight * zoom - viewportHeight) / 2
        )

        panOffset.width = min(
            max(panOffset.width, -maxX),
            maxX
        )

        panOffset.height = min(
            max(panOffset.height, -maxY),
            maxY
        )

    }

    // MARK: - Lokalizacja

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
