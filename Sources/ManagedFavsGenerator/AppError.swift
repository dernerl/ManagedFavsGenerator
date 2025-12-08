import Foundation

/// Zentrales Error Handling für die App
enum AppError: LocalizedError {
    case fileWriteFailed(URL, underlyingError: Error)
    case clipboardAccessFailed
    case invalidURL(String)
    case emptyFavorites
    case fileReadFailed(URL, underlyingError: Error)
    case importInvalidFormat(String)
    case importUnsupportedFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .fileWriteFailed(let url, let error):
            return "Datei konnte nicht gespeichert werden: \(url.lastPathComponent)\nFehler: \(error.localizedDescription)"
        case .clipboardAccessFailed:
            return "Zugriff auf Zwischenablage fehlgeschlagen"
        case .invalidURL(let url):
            return "Ungültige URL: \(url)"
        case .emptyFavorites:
            return "Keine Favoriten zum Exportieren vorhanden"
        case .fileReadFailed(let url, let error):
            return "Datei konnte nicht gelesen werden: \(url.lastPathComponent)\nFehler: \(error.localizedDescription)"
        case .importInvalidFormat(let details):
            return "Ungültiges Dateiformat: \(details)"
        case .importUnsupportedFormat(let ext):
            return "Nicht unterstütztes Dateiformat: .\(ext)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileWriteFailed:
            return "Überprüfen Sie die Schreibrechte und versuchen Sie es erneut."
        case .clipboardAccessFailed:
            return "Starten Sie die App neu oder überprüfen Sie die Systemeinstellungen."
        case .invalidURL:
            return "Geben Sie eine gültige URL ein (z.B. https://example.com)"
        case .emptyFavorites:
            return "Fügen Sie mindestens einen Favoriten hinzu."
        case .fileReadFailed:
            return "Überprüfen Sie die Leserechte und versuchen Sie es erneut."
        case .importInvalidFormat:
            return "Stellen Sie sicher, dass die Datei eine gültige Microsoft Edge Managed Favorites Konfiguration ist."
        case .importUnsupportedFormat:
            return "Nur JSON (.json) und Plist (.plist) Dateien werden unterstützt."
        }
    }
}
