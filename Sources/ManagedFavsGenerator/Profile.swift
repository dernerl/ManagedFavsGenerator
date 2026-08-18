import Foundation
import SwiftData

/// A named, fully independent environment (e.g. "OnPrem", "HomeOffice") — its own
/// favorites tree, target groups, and toplevel name. Nothing is shared between profiles.
@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var name: String
    var toplevelName: String
    var order: Int

    init(id: UUID = UUID(), name: String = "New Profile", toplevelName: String = "managedFavs", order: Int = 0) {
        self.id = id
        self.name = name
        self.toplevelName = toplevelName
        self.order = order
    }
}
