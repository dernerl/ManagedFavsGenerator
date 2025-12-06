import Foundation
import UniformTypeIdentifiers

/// Mock-Service für Tests
@MainActor
final class MockFileService: FileServiceProtocol {
    var savedContent: String?
    var savedDefaultName: String?
    var savedContentType: UTType?
    var shouldReturnURL: URL?
    var shouldThrowError: Error?
    
    func saveFile(content: String, defaultName: String, contentType: UTType) async throws -> URL? {
        savedContent = content
        savedDefaultName = defaultName
        savedContentType = contentType
        
        if let error = shouldThrowError {
            throw error
        }
        
        return shouldReturnURL
    }
}
