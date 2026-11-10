//
//  RegisterView.swift
//  DermaTrack
//
//  Created by Julia Marek on 11/10/2026.
//



//
//  RegisterView.swift
//  DermaTrack
//

import SwiftUI

struct RegisterView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var repeatedPassword = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var registrationSucceeded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Nowe konto") {

                    TextField("Adres e-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        

                    SecureField("Hasło", text: $password)
                        .textContentType(.newPassword)

                    SecureField(
                        "Powtórz hasło",
                        text: $repeatedPassword
                    )
                    .textContentType(.newPassword)

                    Button {
                        Task {
                            await register()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                            }

                            Text(
                                isLoading
                                ? "Rejestrowanie..."
                                : "Zarejestruj się"
                            )
                        }
                    }
                    .disabled(
                        isLoading ||
                        email.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        password.isEmpty ||
                        repeatedPassword.isEmpty ||
                        registrationSucceeded
                    )
                }

                if !message.isEmpty {
                    Section {
                        Label(
                            message,
                            systemImage: registrationSucceeded
                                ? "checkmark.circle.fill"
                                : "exclamationmark.circle"
                        )
                        .foregroundStyle(
                            registrationSucceeded
                                ? .green
                                : .red
                        )
                    }
                }

                if registrationSucceeded {
                    Section {
                        Button("Wróć do logowania") {
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Rejestracja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                }
            }
        }
    }

    @MainActor
    private func register() async {

        message = ""
        registrationSucceeded = false

        // 1. Normalizacja adresu e-mail
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // 2. Sprawdzenie formatu adresu
        let emailPattern =
            #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$"#

        guard normalizedEmail.range(
            of: emailPattern,
            options: .regularExpression
        ) != nil else {
            message = "Podaj poprawny adres e-mail."
            return
        }

        // 3. Sprawdzenie dlugosci hasla
        guard password.count >= 12 else {
            message = "Hasło musi mieć minimum 12 znaków."
            return
        }

        // 4. Porownanie hasel
        guard password == repeatedPassword else {
            message = "Hasła nie są identyczne."
            return
        }

        // 5. Rozpoczecie rejestracji
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            try await AuthService.shared.register(
                email: normalizedEmail,
                password: password
            )

            password = ""
            repeatedPassword = ""

            registrationSucceeded = true

            message = """
            Jeśli rejestracja została przyjęta, \
            sprawdź pocztę e-mail i kliknij link \
            potwierdzający konto.
            """

        } catch {
            message = """
            Nie udało się zarejestrować konta:
            \(error.localizedDescription)
            """
        }
    }
}

#Preview {
    RegisterView()
}
