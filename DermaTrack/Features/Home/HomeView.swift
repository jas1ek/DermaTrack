import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Witaj w DermaTrack")
                    .font(.largeTitle.bold())

                Text("Monitoruj swoje znamiona i obserwuj zmiany w czasie.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Start")
        }
    }
}

#Preview {
    HomeView()
}
