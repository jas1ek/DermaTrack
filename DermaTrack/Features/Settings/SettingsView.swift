import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
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
        }
    }
}

#Preview {
    SettingsView()
}

