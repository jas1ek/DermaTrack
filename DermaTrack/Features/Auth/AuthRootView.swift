//
//  AuthRootView.swift
//  DermaTrack
//
//  Created by Julia Marek on 18/10/2026.
//



import SwiftUI

struct AuthRootView: View {

    @ObservedObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView("Sprawdzanie sesji...")

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

    //Panel pacjenta

    private var patientView: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("DermaTrack")
                    .font(.largeTitle)
                    .bold()

                Text("Zalogowano pomyślnie")
                    .font(.headline)

                Text("Witaj w panelu pacjenta")
                    .foregroundStyle(.secondary)
                
                StorageTestView()

                Button("Wyloguj się") {
                    Task {
                        await auth.logout()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Panel pacjenta")
        }
    }

    //Panel dermatologa

    
    private var dermatologistView: some View {
        VStack(spacing: 0) {
            DermatologistDashboardView()

            Button("Wyloguj się") {
                Task {
                    await auth.logout()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }


    //Błąd pobierania roli

    private var roleErrorView: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Nie udało się ustalić roli")
                    .font(.headline)

                Text(auth.errorMessage ??
                     "Nie można odczytać uprawnień z Supabase.")
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
            .navigationTitle("Błąd uprawnień")
        }
    }
}

#Preview {
    AuthRootView(auth: AuthViewModel())
}
