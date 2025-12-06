import Foundation
import AppKit
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "FileService")

/// Protocol für File-Operationen (für Testbarkeit)
@MainActor
protocol FileServiceProtocol {
    func saveFile(content: String, defaultName: String, contentType: UTType) async throws -> URL?
}

/// Service für File-Operationen (Save/Export)
@MainActor
final class FileService: FileServiceProtocol {
    
    /// Zeigt Save Panel und speichert Datei
    /// - Parameters:
    ///   - content: Der zu speichernde Inhalt
    ///   - defaultName: Standard-Dateiname
    ///   - contentType: Dateityp (z.B. .propertyList)
    /// - Returns: URL der gespeicherten Datei oder nil bei Abbruch
    func saveFile(content: String, defaultName: String, contentType: UTType) async throws -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [contentType]
        savePanel.nameFieldStringValue = defaultName
        savePanel.title = "Export File"
        savePanel.message = "Wählen Sie einen Speicherort für die Datei"
        
        // App in den Vordergrund holen
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Finde das sichtbare Hauptfenster
        let window = NSApplication.shared.windows.first(where: {
            $0.isVisible && $0.canBecomeKey
        })
        
        // Panel als Sheet oder Modal anzeigen
        let response: NSApplication.ModalResponse
        if let window = window {
            response = await savePanel.beginSheetModal(for: window)
        } else {
            response = await savePanel.begin()
        }
        
        // Prüfe Benutzer-Aktion
        guard response == .OK, let url = savePanel.url else {
            logger.info("Export vom Benutzer abgebrochen")
            return nil
        }
        
        // Datei schreiben
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            logger.info("Datei erfolgreich gespeichert: \(url.path)")
            return url
        } catch {
            logger.error("Fehler beim Schreiben der Datei: \(error.localizedDescription)")
            throw AppError.fileWriteFailed(url, underlyingError: error)
        }
    }
}
