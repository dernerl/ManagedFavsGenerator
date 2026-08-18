import Foundation
import SwiftData

/// Ein benannter Zusatz-Satz an Favoriten für eine bestimmte Zielgruppe (z.B. eine Entra-Gruppe),
/// gedacht für die Zuweisung über eine eigene Cloud-Policy im Edge management service.
///
/// `includeBase` steuert, wie diese Gruppe in den Export einfließt:
///   true   Basis-Set bleibt erhalten, die Gruppe wird als Unterordner angehängt
///          (Policy mit niedrigerer Priorität, additiv)
///   false  Eigenständiger Ordner, der das Basis-Set für diese Zielgruppe ersetzt
///          (Policy mit höchster Priorität — ManagedFavorites merged nicht)
@Model
final class TargetGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var includeBase: Bool
    var order: Int
    var profileID: UUID?    // the owning Profile.id

    init(id: UUID = UUID(), name: String = "New Group", includeBase: Bool = true, order: Int = 0, profileID: UUID? = nil) {
        self.id = id
        self.name = name
        self.includeBase = includeBase
        self.order = order
        self.profileID = profileID
    }
}
