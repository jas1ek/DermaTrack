import Foundation

enum DeepLinkDestination: Equatable {
    case lesion(UUID)
}

enum DeepLinkRouter {

    static func parse(_ url: URL) -> DeepLinkDestination? {

        guard url.scheme?.lowercased() == "dermatrack" else {
            return nil
        }

        guard url.host?.lowercased() == "lesion" else {
            return nil
        }

        guard url.user == nil,
              url.password == nil,
              url.port == nil,
              url.query == nil,
              url.fragment == nil else {
            return nil
        }

        let path = url.path.trimmingCharacters(
            in: CharacterSet(charactersIn: "/")
        )

        guard !path.contains("/"),
              let lesionID = UUID(uuidString: path) else {
            return nil
        }

        return .lesion(lesionID)
    }

    static func url(for lesionID: UUID) -> URL? {
        URL(
            string: "dermatrack://lesion/\(lesionID.uuidString)"
        )
    }
}
