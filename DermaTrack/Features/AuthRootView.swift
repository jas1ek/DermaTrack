//
//  AuthRootView.swift
//  DermaTrack
//
//  Created by Jan Bobrzyk on 10/11/2026.
//



import SwiftUI

struct AuthRootView: View {

    @ObservedObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isLoading {
                loadingView

            } else if auth.isLoggedIn {
                switch auth.userRole {

                case .patient:
                    patientView

                case .dermatologist:
                    dermatologistView

                case nil:
                    roleErrorView
                }

            } else {
                LoginView(auth: auth)
            }
        }
        .task {
            await auth.restoreSession()
        }
    }

    // MARK: - Przywracanie sesji

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()

            Text("Sprawdzanie sesji Supabase...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Panel pacjenta

    private var patientView: some View {
        ContentView()
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Label(
                        "Pacjent",
                        systemImage: "person.crop.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("Wyloguj") {
                        Task {
                            await auth.logout()
                        }
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial)
            }
    }

    // MARK: - Panel dermatologa

    private var dermatologistView: some View {
        VStack(spacing: 0) {
            DermatologistDashboardView()

            Button {
                Task {
                    await auth.logout()
                }
            } label: {
                Label(
                    "Wyloguj się",
                    systemImage: "rectangle.portrait.and.arrow.right"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    // MARK: - Błąd odczytu roli

    private var roleErrorView: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)

                Text("Nie udało się ustalić roli")
                    .font(.headline)

                Text(
                    auth.errorMessage ??
                    "Nie można odczytać uprawnień konta z Supabase."
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

                Button("Spróbuj ponownie") {
                    Task {
                        await auth.loadUserRole()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Wyloguj się") {
                    Task {
                        await auth.logout()
                    }
                }
            }
            .padding()
            .navigationTitle("Uprawnienia")
        }
    }
}
