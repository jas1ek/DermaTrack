//
//  AuthViewModel.swift
//  DermaTrack
//
//  Created by Julia Marek on 18/10/2026.
//




import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {

    @Published private(set) var isLoggedIn = false
    @Published private(set) var isLoading = true
    @Published private(set) var userId: UUID?

    // Rola zalogowanego użytkownika
    @Published private(set) var userRole: UserRole?

    @Published var errorMessage: String?

    private let authService = AuthService.shared
    private let profileService = ProfileService()

    //Pobieranie roli użytkownika

    func loadUserRole() async {
        do {
            let profile = try await profileService.getCurrentProfile()
            userRole = profile.role
        } catch {
            userRole = nil
            errorMessage = "Nie można odczytać roli użytkownika: \(error.localizedDescription)"
        }
    }

    //Przywracanie zapisanej sesji

    func restoreSession() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let active = await authService.isLoggedIn()

        let id = active
            ? authService.currentUserID()
            : nil

        userId = id
        isLoggedIn = active && id != nil

        if isLoggedIn {
            await loadUserRole()
        } else {
            userRole = nil
        }
    }

    //Logowanie

    func login(
        email: String,
        password: String
    ) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let normalizedEmail = email
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()

            try await authService.login(
                email: normalizedEmail,
                password: password
            )

            userId = authService.currentUserID()
            isLoggedIn = userId != nil

            if isLoggedIn {
                await loadUserRole()
            } else {
                userRole = nil
            }

        } catch {
            isLoggedIn = false
            userId = nil
            userRole = nil

            errorMessage = "Nieprawidłowy e-mail lub hasło."
        }
    }

    //Wylogowanie

    func logout() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await authService.logout()

            isLoggedIn = false
            userId = nil
            userRole = nil

        } catch {
            errorMessage = "Nie udało się wylogować."
        }
    }
}
