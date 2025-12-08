import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "ViewModel")

@Observable
@MainActor
class FavoritesViewModel {
    // MARK: - Properties
    var toplevelName: String = "managedFavs" {
        didSet {
            // Save to UserDefaults when changed
            UserDefaults.standard.set(toplevelName, forKey: "defaultToplevelName")
        }
    }
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
        
        // Load persisted toplevelName from UserDefaults
        if let savedName = UserDefaults.standard.string(forKey: "defaultToplevelName") {
            self.toplevelName = savedName
        }
    }
    
    // MARK: - Business Logic
    
    func addFavorite(parentID: UUID? = nil) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }
        
        let favorite = Favorite(parentID: parentID)
        modelContext.insert(favorite)
        
        do {
            try modelContext.save()
            logger.info("Favorit hinzugefügt und gespeichert")
        } catch {
            logger.error("Fehler beim Speichern: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func addFolder() {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }
        
        // Folder = Favorite with url = nil
        let folder = Favorite(name: "New Folder", url: nil)
        modelContext.insert(folder)
        
        do {
            try modelContext.save()
            logger.info("Ordner hinzugefügt und gespeichert")
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
    
    // MARK: - Drag & Drop
    
    func moveFavorite(_ favorite: Favorite, toParent newParentID: UUID?, atIndex index: Int, allFavorites: [Favorite]) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }
        
        // Update parentID
        favorite.parentID = newParentID
        
        // Reorder siblings at target location
        let siblings = allFavorites
            .filter { $0.parentID == newParentID && $0.id != favorite.id }
            .sorted { $0.order < $1.order }
        
        // Insert at new position
        var reorderedSiblings = siblings
        let targetIndex = min(index, reorderedSiblings.count)
        reorderedSiblings.insert(favorite, at: targetIndex)
        
        // Update order values
        for (idx, item) in reorderedSiblings.enumerated() {
            item.order = idx
        }
        
        do {
            try modelContext.save()
            logger.info("Favorit verschoben: parentID=\(newParentID?.uuidString ?? "root"), order=\(favorite.order)")
        } catch {
            logger.error("Fehler beim Verschieben: \(error.localizedDescription)")
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
