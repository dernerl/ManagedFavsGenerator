import Foundation

/// Mock ImportService für Unit Tests
@MainActor
final class MockImportService: ImportServiceProtocol {
    var shouldReturnURL: URL?
    var shouldThrowError: Error?
    
    func selectFileForImport() async throws -> URL? {
        if let error = shouldThrowError {
            throw error
        }
        return shouldReturnURL
    }
}
