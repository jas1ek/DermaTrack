import Foundation
import LocalAuthentication

@MainActor
final class BiometricAuthService {

    // MARK: - Rodzaj biometrii

    enum BiometricType {
        case faceID
        case touchID
        case opticID
        case unavailable
    }

    // MARK: - Dostępna biometria

    var biometricType: BiometricType {
        let context = LAContext()

        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return .unavailable
        }

        switch context.biometryType {
        case .faceID:
            return .faceID

        case .touchID:
            return .touchID

        case .opticID:
            return .opticID

        default:
            return .unavailable
        }
    }

    // MARK: - Nazwa mechanizmu

    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"

        case .touchID:
            return "Touch ID"

        case .opticID:
            return "Optic ID"

        case .unavailable:
            return "Biometria niedostępna"
        }
    }

    // MARK: - Uwierzytelnianie

    func authenticate() async throws -> Bool {
        let context = LAContext()

        context.localizedCancelTitle = "Anuluj"

        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {
            throw error ?? BiometricError.authenticationUnavailable
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason:
                "Odblokuj dostęp do dokumentacji zmian skórnych w DermaTrack."
        )
    }

    // MARK: - Błędy

    enum BiometricError: LocalizedError {
        case authenticationUnavailable

        var errorDescription: String? {
            switch self {
            case .authenticationUnavailable:
                return "Uwierzytelnianie na tym urządzeniu jest niedostępne."
            }
        }
    }
}
