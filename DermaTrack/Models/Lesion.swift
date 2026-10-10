
import Foundation

struct Lesion: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var location: String
    var createdAt: Date = Date()
    var notes: String
}
