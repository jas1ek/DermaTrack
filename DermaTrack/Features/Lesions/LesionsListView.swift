import SwiftUI

struct LesionsListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Brak znamion",
                systemImage: "heart.text.square",
                description: Text("Dodane znamiona pojawią się tutaj.")
            )
            .navigationTitle("Moje znamiona")
        }
    }
}

#Preview {
    LesionsListView()
}
