import Foundation
import SwiftData

/// SwiftData Model für Favoriten
@Model
final class Favorite {
    @Attribute(.unique) var id: UUID
    var name: String
    var url: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String = "", url: String = "") {
        self.id = id
        self.name = name
        self.url = url
        self.createdAt = Date()
    }
}
