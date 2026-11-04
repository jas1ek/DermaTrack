import SwiftUI
import AVFoundation
import UIKit

// MARK: - Podgląd aparatu

final class CameraPreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()

        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        return view
    }

    func updateUIView(
        _ view: CameraPreviewUIView,
        context: Context
    ) {
        // Podgląd aktualizuje się automatycznie.
    }
}

// MARK: - Aparat z nakładką poprzedniego zdjęcia

struct CameraView: View {

    let lesionID: UUID

    @EnvironmentObject private var lesionService: LesionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var camera = CameraManager()

    @State private var isSaving = false
    @State private var saveError = false

    // MARK: Nakładka

    @State private var referenceImage: UIImage?
    @State private var overlayEnabled = true
    @State private var overlayOpacity = 0.45

    private var hasReferenceImage: Bool {
        referenceImage != nil
    }

    // MARK: - Główny widok

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if camera.permissionDenied {
                    permissionDeniedView
                } else {
                    cameraContent
                }
            }
            .navigationTitle("Aparat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") {
                        camera.stop()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                loadReferenceImage()
                camera.start()
            }
            .onDisappear {
                camera.stop()
                referenceImage = nil
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    camera.start()

                case .inactive, .background:
                    camera.stop()

                @unknown default:
                    break
                }
            }
            .onChange(of: camera.photoData) { _, data in
                guard let data else { return }
                savePhoto(data)
            }
            .alert(
                "Nie udało się zapisać zdjęcia",
                isPresented: $saveError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "Nie udało się zapisać fotografii. Spróbuj ponownie."
                )
            }
            .alert(
                "Błąd aparatu",
                isPresented: Binding(
                    get: {
                        camera.errorMessage != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            camera.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(camera.errorMessage ?? "")
            }
        }
    }

    // MARK: - Podgląd i sterowanie

    private var cameraContent: some View {
        VStack(spacing: 0) {

            GeometryReader { geometry in
                ZStack {
                    // Obraz na żywo z aparatu
                    CameraPreview(session: camera.session)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()

                    // Poprzednia fotografia jako nakładka
                    if overlayEnabled,
                       let referenceImage {

                        Image(uiImage: referenceImage)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()
                            .opacity(overlayOpacity)
                            .allowsHitTesting(false)
                    }

                    // Oznaczenie aktywnej nakładki
                    if overlayEnabled && hasReferenceImage {
                        VStack {
                            HStack {
                                Label(
                                    "Poprzednie zdjęcie",
                                    systemImage: "square.on.square"
                                )
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    .black.opacity(0.65),
                                    in: Capsule()
                                )

                                Spacer()
                            }

                            Spacer()
                        }
                        .padding(12)
                        .allowsHitTesting(false)
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .clipped()
            }

            // Panel pod podglądem
            VStack(spacing: 16) {

                if hasReferenceImage {
                    overlayControls
                } else {
                    Text(
                        "To pierwsze zdjęcie tego znamienia. Przy kolejnej fotografii pojawi się nakładka poprzedniego kadru."
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                }

                Button {
                    camera.capture()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 76, height: 76)

                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .disabled(isSaving)
                .accessibilityLabel("Wykonaj zdjęcie")

                if isSaving {
                    ProgressView("Zapisywanie zdjęcia...")
                        .tint(.white)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(Color.black)
        }
    }

    // MARK: - Sterowanie nakładką

    private var overlayControls: some View {
        VStack(spacing: 12) {

            Toggle(isOn: $overlayEnabled) {
                Label(
                    "Nakładka poprzedniego zdjęcia",
                    systemImage: "square.on.square"
                )
                .font(.subheadline)
                .foregroundStyle(.white)
            }
            .tint(.teal)

            if overlayEnabled {
                HStack(spacing: 12) {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundStyle(.white.opacity(0.7))

                    Slider(
                        value: $overlayOpacity,
                        in: 0.1...0.9
                    )
                    .tint(.teal)
                    .accessibilityLabel(
                        "Przezroczystość nakładki"
                    )

                    Text("\(Int(overlayOpacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 40)
                }
            }

            Text(
                "Dopasuj położenie aparatu do poprzedniego zdjęcia. Nakładka nie zostanie zapisana na fotografii."
            )
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.65))
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Wczytywanie poprzedniego kadru

    private func loadReferenceImage() {
        let urls = lesionService.photoURLs(for: lesionID)

        guard let lastURL = urls.last else {
            referenceImage = nil
            overlayEnabled = false
            return
        }

        referenceImage = UIImage(
            contentsOfFile: lastURL.path
        )

        overlayEnabled = referenceImage != nil
        overlayOpacity = 0.45
    }

    // MARK: - Brak uprawnienia do aparatu

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {

            Image(systemName: "camera.slash.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white)

            Text("Brak dostępu do aparatu")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(
                "Aby wykonywać zdjęcia zmian skórnych, zezwól DermaTrack na dostęp do aparatu w Ustawieniach iPhone'a."
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.75))

            Button {
                openAppSettings()
            } label: {
                Label(
                    "Otwórz Ustawienia",
                    systemImage: "gearshape"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Zamknij") {
                dismiss()
            }
            .foregroundStyle(.white)
        }
        .padding(24)
    }

    // MARK: - Otwieranie ustawień iOS

    private func openAppSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }

    // MARK: - Zapisywanie fotografii

    private func savePhoto(_ data: Data) {
        guard !isSaving else { return }

        isSaving = true

        do {
            try lesionService.addPhoto(
                data,
                to: lesionID
            )

            camera.stop()
            dismiss()

        } catch {
            isSaving = false
            saveError = true
        }
    }
}

// MARK: - Aparat podczas dodawania nowego znamienia

struct DraftCameraView: View {

    let onCaptured: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var camera = CameraManager()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if camera.permissionDenied {
                    permissionDeniedContent
                } else {
                    cameraContent
                }
            }
            .navigationTitle("Zrób zdjęcie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
                        camera.stop()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                camera.start()
            }
            .onDisappear {
                camera.stop()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    camera.start()

                case .inactive, .background:
                    camera.stop()

                @unknown default:
                    break
                }
            }
            .onChange(of: camera.photoData) { _, data in
                guard let data else { return }

                onCaptured(data)
                camera.stop()
                dismiss()
            }
            .alert(
                "Błąd aparatu",
                isPresented: Binding(
                    get: {
                        camera.errorMessage != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            camera.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(camera.errorMessage ?? "")
            }
        }
    }

    // MARK: - Podgląd aparatu

    private var cameraContent: some View {
        VStack(spacing: 16) {

            CameraPreview(session: camera.session)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipped()

            Button {
                camera.capture()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 76, height: 76)

                    Circle()
                        .fill(.white)
                        .frame(width: 60, height: 60)
                }
            }
            .accessibilityLabel("Wykonaj zdjęcie")
            .padding(.bottom, 20)
        }
    }

    // MARK: - Obsługa odmowy uprawnienia

    private var permissionDeniedContent: some View {
        VStack(spacing: 20) {

            Image(systemName: "camera.slash")
                .font(.system(size: 48))

            Text("Brak dostępu do aparatu")
                .font(.headline)

            Text(
                "Zezwól DermaTrack na dostęp do aparatu w Ustawieniach iPhone'a."
            )
            .multilineTextAlignment(.center)

            Button("Otwórz Ustawienia") {
                guard let url = URL(
                    string: UIApplication.openSettingsURLString
                ) else {
                    return
                }

                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)

            Button("Zamknij") {
                dismiss()
            }
        }
        .foregroundStyle(.white)
        .padding()
    }
}
