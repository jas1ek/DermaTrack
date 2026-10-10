
import SwiftUI

struct SettingsView: View {
    @AppStorage("bodySilhouetteStyle")
    private var silhouetteStyle = BodySilhouetteStyle.male.rawValue

    var body: some View {
        NavigationStack {
            Form {
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
