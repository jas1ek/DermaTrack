import SwiftUI

struct BodyMapView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Mapa ciała",
                systemImage: "figure.stand",
                description: Text("Tutaj będziesz zaznaczać lokalizację znamion.")
            )
            .navigationTitle("Mapa ciała")
        }
    }
}

#Preview {
    BodyMapView()
}
