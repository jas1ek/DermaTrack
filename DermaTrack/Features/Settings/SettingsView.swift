import SwiftUI
import LocalAuthentication

struct SettingsView: View {

    // MARK: - Mapa ciała

    @AppStorage("bodySilhouetteStyle")
    private var silhouetteStyle = BodySilhouetteStyle.male.rawValue

    // MARK: - Blokada biometryczna

    @AppStorage("biometricLockEnabled")
    private var biometricLockEnabled = false

    @State private var isAuthenticating = false
    @State private var showAuthError = false
    @State private var authErrorMessage = ""

    private let biometricService = BiometricAuthService()

    // MARK: - Widok główny

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Mapa ciała

                Section("Mapa ciała") {
                    Picker(
                        "Rodzaj sylwetki",
                        selection: $silhouetteStyle
                    ) {
                        ForEach(BodySilhouetteStyle.allCases) { style in
                            Text(style.title)
                                .tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(
                        "Wybrana sylwetka będzie używana na mapie ciała."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                // MARK: Bezpieczeństwo

                Section {
                    Toggle(
                        isOn: Binding(
                            get: {
                                biometricLockEnabled
                            },
                            set: { newValue in
                                changeBiometricLock(to: newValue)
                            }
                        )
                    ) {
                        Label(
                            "Blokada biometryczna",
                            systemImage: "faceid"
                        )
                    }
                    .disabled(isAuthenticating)

                    if isAuthenticating {
                        HStack(spacing: 12) {
                            ProgressView()

                            Text("Weryfikowanie tożsamości...")
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent(
                        "Metoda odblokowania",
                        value: biometricService.biometricName
                    )

                } header: {
                    Text("Bezpieczeństwo")
                } footer: {
                    Text(
                        "Po włączeniu blokady dostęp do DermaTrack będzie wymagał uwierzytelnienia za pomocą Face ID, Touch ID lub kodu urządzenia. Funkcja nie zastępuje logowania do konta."
                    )
                }

                // MARK: Informacje

                Section("Informacje") {
                    LabeledContent(
                        "Aplikacja",
                        value: "DermaTrack"
                    )

                    LabeledContent(
                        "Wersja",
                        value: "0.1"
                    )
                }
            }
            .navigationTitle("Ustawienia")
            .alert(
                "Nie udało się zmienić blokady",
                isPresented: $showAuthError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authErrorMessage)
            }
        }
    }

    // MARK: - Zmiana ustawienia blokady

    private func changeBiometricLock(to newValue: Bool) {
        guard !isAuthenticating else {
            return
        }

        // Nie zmieniamy ustawienia przed uwierzytelnieniem.
        isAuthenticating = true

        Task { @MainActor in
            defer {
                isAuthenticating = false
            }

            do {
                let authenticated =
                    try await biometricService.authenticate()

                if authenticated {
                    biometricLockEnabled = newValue
                } else {
                    authErrorMessage =
                        "Nie udało się potwierdzić tożsamości."
                    showAuthError = true
                }

            } catch {
                authErrorMessage =
                    "Uwierzytelnianie nie powiodło się: \(error.localizedDescription)"

                showAuthError = true
            }
        }
    }
}

#Preview {
    SettingsView()
}
