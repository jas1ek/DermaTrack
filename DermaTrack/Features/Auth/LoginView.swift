//
//  LoginView.swift
//  DermaTrack
//
//  Created by Julia Marek on 11/10/2026.
//


import SwiftUI

struct LoginView: View {

    @ObservedObject var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Logowanie") {

                    TextField("Adres e-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Hasło", text: $password)
                        .textContentType(.password)

                    Button {
                        Task {
                            await auth.login(
                                email: email,
                                password: password
                            )

                            if auth.isLoggedIn {
                                password = ""
                            }
                        }
                    } label: {
                        HStack {
                            if auth.isLoading {
                                ProgressView()
                            }

                            Text("Zaloguj się")
                        }
                    }
                    .disabled(
                        auth.isLoading ||
                        email.isEmpty ||
                        password.isEmpty
                    )
                }

                if let error = auth.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Utwórz nowe konto") {
                        showRegister = true
                    }
                }
            }
            .navigationTitle("DermaTrack")
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView(auth: AuthViewModel())
}
