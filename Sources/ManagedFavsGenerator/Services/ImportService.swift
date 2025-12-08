import Foundation
import AppKit
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "ImportService")

/// Protocol für Import-Operationen (für Testbarkeit)
@MainActor
protocol ImportServiceProtocol {
    func selectFileForImport() async throws -> URL?
}

/// Service für Import-Operationen (Open/Load)
@MainActor
final class ImportService: ImportServiceProtocol {
    
    /// Zeigt Open Panel für Dateiauswahl
    /// - Returns: URL der ausgewählten Datei oder nil bei Abbruch
    func selectFileForImport() async throws -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json, .propertyList]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Import Configuration"
        openPanel.message = "Wählen Sie eine JSON- oder Plist-Konfigurationsdatei"
        openPanel.prompt = "Import"
        
        // App in den Vordergrund holen
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Finde das sichtbare Hauptfenster
        let window = NSApplication.shared.windows.first(where: {
            $0.isVisible && $0.canBecomeKey
        })
        
        // Panel als Sheet oder Modal anzeigen
        let response: NSApplication.ModalResponse
        if let window = window {
            response = await openPanel.beginSheetModal(for: window)
        } else {
            response = await openPanel.begin()
        }
        
        // Prüfe Benutzer-Aktion
        guard response == .OK, let url = openPanel.url else {
            logger.info("Import vom Benutzer abgebrochen")
            return nil
        }
        
        logger.info("Datei für Import ausgewählt: \(url.path)")
        return url
    }
}
