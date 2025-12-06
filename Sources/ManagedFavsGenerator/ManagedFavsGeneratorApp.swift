import SwiftUI
import SwiftData

/// Managed Favs Generator - macOS App zur Generierung von Browser Favoriten
///
/// Diese App generiert Plist-Dateien für Microsoft Edge Managed Favorites.
/// Implementiert robustes Keyboard-Focus-Management via AppDelegate.
@main
struct ManagedFavsGeneratorApp: App {
    /// AppDelegate für Window- und Focus-Management
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// SwiftData ModelContainer
    let modelContainer: ModelContainer
    
    init() {
        do {
            // ModelContainer für Favorite Model erstellen
            modelContainer = try ModelContainer(for: Favorite.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 950, minHeight: 600)
        }
        .modelContainer(modelContainer)
        .commands {
            // Entfernt "New Item" aus dem File-Menü
            CommandGroup(replacing: .newItem) {}
        }
        .defaultSize(width: 1200, height: 700)
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        
        // Settings Scene
        Settings {
            SettingsView()
        }
    }
}
