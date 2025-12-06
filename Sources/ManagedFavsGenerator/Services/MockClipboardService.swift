import Foundation

/// Mock-Service für Tests
@MainActor
final class MockClipboardService: ClipboardServiceProtocol {
    var copiedText: String?
    var shouldThrowError = false
    
    func copyToClipboard(_ text: String) throws {
        if shouldThrowError {
            throw AppError.clipboardAccessFailed
        }
        copiedText = text
    }
}
