
import Foundation
import AVFoundation
import Combine

final class CameraManager: NSObject, ObservableObject,
                           AVCapturePhotoCaptureDelegate {

    let session = AVCaptureSession()

    @Published var photoData: Data?
    @Published var errorMessage: String?
    @Published var permissionDenied = false

    private let sessionQueue = DispatchQueue(
        label: "dermatrack.camera.session"
    )

    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false

    // MARK: - Uprawnienia

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {

        case .authorized:
            DispatchQueue.main.async {
                self.permissionDenied = false
            }
            configureAndStart()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }

                DispatchQueue.main.async {
                    self.permissionDenied = !granted
                }

                if granted {
                    self.configureAndStart()
                }
            }

        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionDenied = true
            }

        @unknown default:
            DispatchQueue.main.async {
                self.permissionDenied = true
            }
        }
    }

    // MARK: - Konfiguracja aparatu

    private func configureAndStart() {
        sessionQueue.async {
            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                guard let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                ) else {
                    self.session.commitConfiguration()
                    self.showError("Nie znaleziono aparatu.")
                    return
                }

                do {
                    let input = try AVCaptureDeviceInput(
                        device: device
                    )

                    guard self.session.canAddInput(input),
                          self.session.canAddOutput(self.photoOutput) else {
                        self.session.commitConfiguration()
                        self.showError(
                            "Nie można skonfigurować aparatu."
                        )
                        return
                    }

                    self.session.addInput(input)
                    self.session.addOutput(self.photoOutput)
                    self.session.commitConfiguration()

                    self.isConfigured = true

                } catch {
                    self.session.commitConfiguration()
                    self.showError(
                        "Błąd uruchamiania aparatu: \(error.localizedDescription)"
                    )
                    return
                }
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    // MARK: - Wykonanie zdjęcia

    func capture() {
        sessionQueue.async {
            guard self.isConfigured,
                  self.session.isRunning else {
                return
            }

            let settings = AVCapturePhotoSettings()

            self.photoOutput.capturePhoto(
                with: settings,
                delegate: self
            )
        }
    }

    // MARK: - Zatrzymanie aparatu

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - Odbiór fotografii
    

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            let message = error.localizedDescription

            Task { @MainActor [weak self] in
                self?.errorMessage = message
            }
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            Task { @MainActor [weak self] in
                self?.errorMessage =
                    "Nie udało się odczytać zdjęcia."
            }
            return
        }

        Task { @MainActor [weak self] in
            self?.photoData = data
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
}
