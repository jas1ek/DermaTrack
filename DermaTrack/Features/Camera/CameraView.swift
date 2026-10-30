
import SwiftUI
import AVFoundation
import UIKit

// MARK: - Podgląd obrazu z aparatu

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

// MARK: - Ekran aparatu DermaTrack

struct CameraView: View {

    let lesionID: UUID

    @EnvironmentObject private var lesionService: LesionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var camera = CameraManager()

    @State private var saveError = false
    @State private var isSaving = false
    @State private var showSettingsHint = false

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

            // Uruchomienie aparatu
            .onAppear {
                camera.start()
            }

            // Zatrzymanie aparatu po zamknięciu ekranu
            .onDisappear {
                camera.stop()
            }

            // Ponowne sprawdzenie uprawnień
            // po powrocie z Ustawień iPhone'a
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    camera.start()

                case .inactive, .background:
                    camera.stop()

                @unknown default:
                    break
                }
            }

            // Obsługa wykonanego zdjęcia
            .onChange(of: camera.photoData) { _, newData in
                guard let newData else {
                    return
                }

                savePhoto(newData)
            }

            // Błąd zapisu fotografii
            .alert(
                "Nie udało się zapisać zdjęcia",
                isPresented: $saveError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "Spróbuj ponownie wykonać zdjęcie."
                )
            }

            // Błąd aparatu
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

    // MARK: - Widok aparatu

    private var cameraContent: some View {
        VStack(spacing: 0) {

            CameraPreview(session: camera.session)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipped()

            VStack(spacing: 16) {

                Text("Ustaw zmianę skórną w kadrze")
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Button {
                    camera.capture()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                Color.white,
                                lineWidth: 4
                            )
                            .frame(
                                width: 76,
                                height: 76
                            )

                        Circle()
                            .fill(Color.white)
                            .frame(
                                width: 60,
                                height: 60
                            )
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
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.black)
        }
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

    // MARK: - Zapisywanie zdjęcia

    private func savePhoto(_ data: Data) {
        guard !isSaving else {
            return
        }

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
                    VStack(spacing: 20) {
                        Image(systemName: "camera.slash")
                            .font(.system(size: 48))

                        Text("Brak dostępu do aparatu")
                            .font(.headline)

                        Text("Zezwól DermaTrack na dostęp do aparatu w Ustawieniach iPhone'a.")
                            .multilineTextAlignment(.center)

                        Button("Otwórz Ustawienia") {
                            guard let url = URL(
                                string: UIApplication.openSettingsURLString
                            ) else { return }

                            UIApplication.shared.open(url)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .foregroundStyle(.white)
                    .padding()
                } else {
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
            }
            .navigationTitle("Zrób zdjęcie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
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
                if phase == .active {
                    camera.start()
                } else if phase == .background {
                    camera.stop()
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
                    get: { camera.errorMessage != nil },
                    set: {
                        if !$0 {
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
}

