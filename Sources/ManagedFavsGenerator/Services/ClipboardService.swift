import Foundation
import AppKit
import OSLog

private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "ClipboardService")

/// Protocol für Clipboard-Operationen (für Testbarkeit)
@MainActor
protocol ClipboardServiceProtocol {
    func copyToClipboard(_ text: String) throws
}

/// Service für Clipboard-Operationen
@MainActor
final class ClipboardService: ClipboardServiceProtocol {
    
    func copyToClipboard(_ text: String) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        guard pasteboard.setString(text, forType: .string) else {
            logger.error("Clipboard-Zugriff fehlgeschlagen")
            throw AppError.clipboardAccessFailed
        }
        
        logger.info("Text erfolgreich in Zwischenablage kopiert")
    }
}
