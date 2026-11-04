import SwiftUI
import UIKit

struct PhotoComparisonView: View {

    let lesionID: UUID

    @EnvironmentObject private var lesionService: LesionService
    @Environment(\.dismiss) private var dismiss

    @State private var olderPhoto: URL?
    @State private var newerPhoto: URL?

    @State private var comparisonMode = 0
    @State private var sliderPosition = 0.5

    private var photos: [URL] {
        _ = lesionService.photoVersion
        return lesionService.photoURLs(for: lesionID)
    }

    private var canCompare: Bool {
        olderPhoto != nil &&
        newerPhoto != nil &&
        olderPhoto != newerPhoto
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                if photos.count < 2 {
                    ContentUnavailableView(
                        "Za mało zdjęć",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text(
                            "Dodaj co najmniej dwie fotografie tego znamienia, aby je porównać."
                        )
                    )
                } else {

                    photoSelection

                    Picker("Tryb porównania", selection: $comparisonMode) {
                        Text("Obok siebie").tag(0)
                        Text("Suwak").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if canCompare {
                        if comparisonMode == 0 {
                            sideBySideComparison
                        } else {
                            sliderComparison
                        }
                    } else {
                        ContentUnavailableView(
                            "Wybierz dwa zdjęcia",
                            systemImage: "rectangle.split.2x1",
                            description: Text(
                                "Wskaż starszą i nowszą fotografię."
                            )
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Porównanie zdjęć")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setDefaultPhotos()
        }
        .onChange(of: lesionService.photoVersion) { _, _ in
            ensureValidSelection()
        }
    }

    // MARK: - Wybór fotografii

    private var photoSelection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Wybierz fotografie")
                .font(.headline)

            Picker("Starsze zdjęcie", selection: $olderPhoto) {
                Text("Wybierz").tag(Optional<URL>.none)

                ForEach(photos, id: \.self) { url in
                    Text(photoLabel(for: url))
                        .tag(Optional(url))
                }
            }

            Picker("Nowsze zdjęcie", selection: $newerPhoto) {
                Text("Wybierz").tag(Optional<URL>.none)

                ForEach(photos, id: \.self) { url in
                    Text(photoLabel(for: url))
                        .tag(Optional(url))
                }
            }

            if olderPhoto == newerPhoto {
                Text("Wybierz dwie różne fotografie.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Porównanie obok siebie

    private var sideBySideComparison: some View {
        HStack(alignment: .top, spacing: 12) {

            comparisonPhoto(
                url: olderPhoto,
                title: "Starsze zdjęcie"
            )

            comparisonPhoto(
                url: newerPhoto,
                title: "Nowsze zdjęcie"
            )
        }
    }

    private func comparisonPhoto(
        url: URL?,
        title: String
    ) -> some View {

        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)

            if let url,
               let image = UIImage(contentsOfFile: url.path) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .background(.black.opacity(0.05))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )

            } else {
                ContentUnavailableView(
                    "Brak zdjęcia",
                    systemImage: "photo"
                )
                .frame(height: 250)
            }

            if let url {
                Text(photoLabel(for: url))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Porównanie za pomocą suwaka

    private var sliderComparison: some View {
        VStack(spacing: 12) {

            Text("Przesuwaj suwak, aby porównać zdjęcia")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in

                let width = geometry.size.width
                let height = geometry.size.height
                let dividerX = width * sliderPosition

                ZStack(alignment: .leading) {

                    comparisonImage(
                        url: newerPhoto,
                        width: width,
                        height: height
                    )

                    comparisonImage(
                        url: olderPhoto,
                        width: width,
                        height: height
                    )
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: dividerX)
                    }

                    Rectangle()
                        .fill(.white)
                        .frame(width: 3)
                        .offset(x: dividerX - 1.5)

                    Image(systemName: "arrow.left.and.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                        .offset(x: dividerX - 16)
                }
                .frame(width: width, height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            sliderPosition = min(
                                max(value.location.x / max(width, 1), 0),
                                1
                            )
                        }
                )
            }
            .frame(height: 330)

            Slider(value: $sliderPosition, in: 0...1)

            HStack {
                Text("Starsze")
                Spacer()
                Text("Nowsze")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func comparisonImage(
        url: URL?,
        width: CGFloat,
        height: CGFloat
    ) -> some View {

        Group {
            if let url,
               let image = UIImage(contentsOfFile: url.path) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()

            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(width: width, height: height)
            }
        }
    }

    // MARK: - Domyślny wybór

    private func setDefaultPhotos() {
        guard photos.count >= 2 else { return }

        olderPhoto = photos[photos.count - 2]
        newerPhoto = photos[photos.count - 1]
    }

    private func ensureValidSelection() {
        guard photos.count >= 2 else {
            olderPhoto = nil
            newerPhoto = nil
            return
        }

        if let olderPhoto, !photos.contains(olderPhoto) {
            self.olderPhoto = photos[photos.count - 2]
        }

        if let newerPhoto, !photos.contains(newerPhoto) {
            self.newerPhoto = photos[photos.count - 1]
        }
    }

    // MARK: - Opis fotografii

    private func photoLabel(for url: URL) -> String {
        let values = try? url.resourceValues(
            forKeys: [.creationDateKey]
        )

        if let date = values?.creationDate {
            return date.formatted(
                date: .abbreviated,
                time: .shortened
            )
        }

        return url.lastPathComponent
    }
}

