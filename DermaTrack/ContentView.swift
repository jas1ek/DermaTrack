
//
//  ContentView.swift
//  DermaTrack
//
//  Created by Jan Bobrzyk and Julia Marek on 09/10/2026.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Dane aplikacji

    @StateObject private var lesionService = LesionService()

    // MARK: - Blokada biometryczna

    @AppStorage("biometricLockEnabled")
    private var biometricLockEnabled = false

    @Environment(\.scenePhase)
    private var scenePhase

    @State private var isUnlocked = false
    @State private var isAuthenticating = false
    @State private var authenticationError: String?

    private let biometricService = BiometricAuthService()

    // MARK: - Deep linki

    @State private var pendingLesionID: UUID?
    @State private var presentedLesion: LinkedLesion?
    @State private var showLinkError = false
    @State private var linkErrorMessage = ""

    private var hasAccessToInterface: Bool {
        !biometricLockEnabled || (
            isUnlocked && scenePhase == .active
        )
    }

    // MARK: - Widok główny

    var body: some View {
        Group {
            if hasAccessToInterface {
                mainTabView
            } else {
                lockScreen
            }
        }
        .environmentObject(lesionService)
        .task { await lesionService.refresh() }
        .onDisappear { lesionService.clearSession() }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                lockApplication()
            }

            if phase == .active {
                openPendingLesionIfAllowed()
            }
        }
        .onChange(of: biometricLockEnabled) { _, enabled in
            if enabled {
                lockApplication()
            } else {
                isUnlocked = false
                authenticationError = nil
                openPendingLesionIfAllowed()
            }
        }
        .onChange(of: isUnlocked) { _, unlocked in
            if unlocked {
                openPendingLesionIfAllowed()
            }
        }
        .sheet(item: $presentedLesion) { linkedLesion in
            NavigationStack {
                LesionDetailView(
                    lesionID: linkedLesion.id
                )
                .environmentObject(lesionService)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zamknij") {
                            presentedLesion = nil
                        }
                    }
                }
            }
        }
        .alert(
            "Nie można otworzyć linku",
            isPresented: $showLinkError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(linkErrorMessage)
        }
    }

    // MARK: - Zakładki

    private var mainTabView: some View {
        TabView {

            HomeView()
                .tabItem {
                    Label("Start", systemImage: "house")
                }

            LesionsListView()
                .tabItem {
                    Label("Znamiona", systemImage: "list.bullet")
                }

            BodyMapView()
                .tabItem {
                    Label("Mapa ciała", systemImage: "figure.stand")
                }

            NavigationStack {
                ClinicsMapView()
            }
            .tabItem {
                Label("Gabinety", systemImage: "cross.case")
            }

            SettingsView()
                .tabItem {
                    Label("Ustawienia", systemImage: "gearshape")
                }
        }
        .tint(.teal)
    }

    // MARK: - Ekran blokady

    private var lockScreen: some View {
        VStack(spacing: 24) {

            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.teal)

            Text("DermaTrack")
                .font(.largeTitle.bold())

            Text("Aplikacja jest zablokowana")
                .font(.title3)
                .fontWeight(.semibold)

            Text(
                "Potwierdź tożsamość, aby uzyskać dostęp do dokumentacji zmian skórnych."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            if let authenticationError {
                Text(authenticationError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                unlockApplication()
            } label: {
                HStack(spacing: 12) {
                    if isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                    }

                    Text(
                        isAuthenticating
                        ? "Uwierzytelnianie..."
                        : "Odblokuj"
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .disabled(isAuthenticating)

            Text(
                "Możesz użyć Face ID, Touch ID lub kodu urządzenia."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Blokada

    private func lockApplication() {
        isUnlocked = false
        authenticationError = nil

        // Ukrywamy szczegóły otwarte przez deep link.
        if let presentedLesion {
            pendingLesionID = presentedLesion.id
            self.presentedLesion = nil
        }
    }

    private func unlockApplication() {
        guard !isAuthenticating else {
            return
        }

        authenticationError = nil
        isAuthenticating = true

        Task { @MainActor in
            defer {
                isAuthenticating = false
            }

            do {
                let authenticated =
                    try await biometricService.authenticate()

                guard biometricLockEnabled else {
                    return
                }

                if authenticated {
                    isUnlocked = true
                    authenticationError = nil
                } else {
                    isUnlocked = false
                    authenticationError =
                        "Nie udało się potwierdzić tożsamości."
                }

            } catch {
                isUnlocked = false
                authenticationError =
                    "Nie udało się odblokować aplikacji: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Obsługa deep linków

    private func handleDeepLink(_ url: URL) {
        guard let destination = DeepLinkRouter.parse(url) else {
            pendingLesionID = nil
            showLinkError = true
            linkErrorMessage = "Nieprawidłowy adres linku."
            return
        }

        switch destination {
        case .lesion(let id):
            pendingLesionID = id
            openPendingLesionIfAllowed()
        }
    }

    private func openPendingLesionIfAllowed() {

        // Nie pokazujemy danych przy aktywnej blokadzie.
        guard hasAccessToInterface else {
            return
        }

        guard let id = pendingLesionID else {
            return
        }

        // Wersja lokalna: sprawdzamy, czy znamię
        // istnieje w bieżącej dokumentacji.
        guard lesionService.lesions.contains(
            where: { $0.id == id }
        ) else {
            pendingLesionID = nil
            showLinkError = true
            linkErrorMessage =
                "Nie znaleziono wskazanego znamienia."
            return
        }

        pendingLesionID = nil
        presentedLesion = LinkedLesion(id: id)
    }
}

// MARK: - Identyfikator prezentowanego znamienia

private struct LinkedLesion: Identifiable {
    let id: UUID
}

#Preview {
    ContentView()
}
