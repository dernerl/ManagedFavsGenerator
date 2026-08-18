import Foundation
import SwiftData

/// SwiftData Model für Favoriten und Ordner
// Note: @Model is a SwiftData macro, not a GitHub user mention
@Model
final class Favorite {
    @Attribute(.unique) var id: UUID
    var name: String
    var url: String?        // nil = Folder, String = Favorite
    var parentID: UUID?     // nil = Root level, UUID = Inside folder
    var order: Int = 0      // For sorting within same level (default: 0)
    var createdAt: Date
    var groupID: UUID?      // nil = belongs to the base tree, otherwise the owning TargetGroup.id

    /// Computed property to check if this is a folder
    var isFolder: Bool {
        url == nil
    }

    init(id: UUID = UUID(), name: String = "", url: String? = "", parentID: UUID? = nil, order: Int = 0, groupID: UUID? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.parentID = parentID
        self.order = order
        self.createdAt = Date()
        self.groupID = groupID
    }
}
