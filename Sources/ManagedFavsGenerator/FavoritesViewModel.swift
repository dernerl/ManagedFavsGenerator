import Foundation
import SwiftData
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "ViewModel")

@Observable
@MainActor
class FavoritesViewModel {
    // MARK: - Properties
    var toplevelName: String = "managedFavs"
    var showCopiedFeedback: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    
    // MARK: - Services (Dependency Injection)
    private let clipboardService: ClipboardServiceProtocol
    private let fileService: FileServiceProtocol
    
    // MARK: - SwiftData Context
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    init(
        clipboardService: ClipboardServiceProtocol = ClipboardService(),
        fileService: FileServiceProtocol = FileService(),
        modelContext: ModelContext? = nil
    ) {
        self.clipboardService = clipboardService
        self.fileService = fileService
        self.modelContext = modelContext
    }
    
    // MARK: - Business Logic
    
    func addFavorite() {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }
        
        let favorite = Favorite()
        modelContext.insert(favorite)
        
        do {
            try modelContext.save()
            logger.info("Favorit hinzugefügt und gespeichert")
        } catch {
            logger.error("Fehler beim Speichern: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func removeFavorite(_ favorite: Favorite) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }
        
        modelContext.delete(favorite)
        
        do {
            try modelContext.save()
            logger.info("Favorit entfernt")
        } catch {
            logger.error("Fehler beim Löschen: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func copyToClipboard(_ text: String) {
        do {
            try clipboardService.copyToClipboard(text)
            
            showCopiedFeedback = true
            logger.info("Text in Zwischenablage kopiert")
            
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                showCopiedFeedback = false
            }
        } catch {
            handleError(error)
        }
    }
    
    func exportPlist(favorites: [Favorite]) async {
        do {
            // Validierung
            guard !favorites.isEmpty else {
                throw AppError.emptyFavorites
            }
            
            // Content generieren
            let plistContent = FormatGenerator.generatePlist(
                toplevelName: toplevelName,
                favorites: favorites
            )
            
            // Datei speichern via Service
            let savedUrl = try await fileService.saveFile(
                content: plistContent,
                defaultName: "ManagedFavorites.plist",
                contentType: .propertyList
            )
            
            if let url = savedUrl {
                logger.info("Plist erfolgreich exportiert: \(url.path)")
            } else {
                logger.info("Export abgebrochen")
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        logger.error("Fehler aufgetreten: \(error.localizedDescription)")
        
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
        } else {
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten: \(error.localizedDescription)"
        }
        
        showError = true
    }
}
