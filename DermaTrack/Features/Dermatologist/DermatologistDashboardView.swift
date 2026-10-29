//
//  DermatologistDashboardView.swift
//  DermaTrack
//
//  Created by Julia Marek on 29/10/2026.
//



import SwiftUI

struct DermatologistDashboardView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 55))
                        .foregroundStyle(.blue)

                    Text("Panel dermatologa")
                        .font(.title)
                        .bold()

                    Text("Zalogowano jako dermatolog")
                        .foregroundStyle(.secondary)

                    Text("Tutaj pojawią się znamiona udostępnione przez pacjentów.")
                        .multilineTextAlignment(.center)
                        .padding()

                    // Tymczasowy test zabezpieczeń Supabase
                    StorageTestView()

                }
                .padding()
            }
            .navigationTitle("DermaTrack")
        }
    }
}

#Preview {
    DermatologistDashboardView()
}

