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
    var showCopiedFeedback: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Services (Dependency Injection)
    private let clipboardService: ClipboardServiceProtocol
    private let fileService: FileServiceProtocol
    private let importService: ImportServiceProtocol

    // MARK: - SwiftData Context
    private var modelContext: ModelContext?

    // MARK: - Initialization
    init(
        clipboardService: ClipboardServiceProtocol = ClipboardService(),
        fileService: FileServiceProtocol = FileService(),
        importService: ImportServiceProtocol = ImportService(),
        modelContext: ModelContext? = nil
    ) {
        self.clipboardService = clipboardService
        self.fileService = fileService
        self.importService = importService
        self.modelContext = modelContext
    }

    // MARK: - Business Logic

    func addFavorite(parentID: UUID? = nil, profileID: UUID?) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }

        let favorite = Favorite(parentID: parentID, profileID: profileID)
        modelContext.insert(favorite)

        do {
            try modelContext.save()
            logger.info("Favorit hinzugefügt und gespeichert")
        } catch {
            logger.error("Fehler beim Speichern: \(error.localizedDescription)")
            handleError(error)
        }
    }

    func addFolder(profileID: UUID?) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }

        // Folder = Favorite with url = nil
        let folder = Favorite(name: "New Folder", url: nil, profileID: profileID)
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

    // MARK: - Target Groups

    func addTargetGroup(profileID: UUID?) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }

        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<TargetGroup>())) ?? 0
        let group = TargetGroup(order: existingCount, profileID: profileID)
        modelContext.insert(group)

        do {
            try modelContext.save()
            logger.info("Zielgruppe hinzugefügt und gespeichert")
        } catch {
            logger.error("Fehler beim Speichern: \(error.localizedDescription)")
            handleError(error)
        }
    }

    func removeTargetGroup(_ group: TargetGroup, favorites: [Favorite]) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }

        for favorite in favorites where favorite.groupID == group.id {
            modelContext.delete(favorite)
        }
        modelContext.delete(group)

        do {
            try modelContext.save()
            logger.info("Zielgruppe entfernt")
        } catch {
            logger.error("Fehler beim Löschen: \(error.localizedDescription)")
            handleError(error)
        }
    }

    func addGroupFavorite(groupID: UUID, profileID: UUID?) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }

        let favorite = Favorite(groupID: groupID, profileID: profileID)
        modelContext.insert(favorite)

        do {
            try modelContext.save()
            logger.info("Favorit zu Zielgruppe hinzugefügt und gespeichert")
        } catch {
            logger.error("Fehler beim Speichern: \(error.localizedDescription)")
            handleError(error)
        }
    }

    // MARK: - Profiles

    /// Creates a new, independent profile and returns it so the caller can switch to it.
    @discardableResult
    func addProfile() -> Profile? {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return nil
        }

        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<Profile>())) ?? 0
        let profile = Profile(order: existingCount)
        modelContext.insert(profile)

        do {
            try modelContext.save()
            logger.info("Profil hinzugefügt und gespeichert")
        } catch {
            logger.error("Fehler beim Speichern: \(error.localizedDescription)")
            handleError(error)
        }
        return profile
    }

    /// Deletes a profile and everything scoped to it (its favorites and target groups).
    func removeProfile(_ profile: Profile, favorites: [Favorite], groups: [TargetGroup]) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }

        let profileID = profile.id
        for favorite in favorites where favorite.profileID == profileID {
            modelContext.delete(favorite)
        }
        for group in groups where group.profileID == profileID {
            modelContext.delete(group)
        }
        modelContext.delete(profile)

        do {
            try modelContext.save()
            logger.info("Profil entfernt")
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

    func exportPlist(favorites: [Favorite], toplevelName: String) async {
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

    // MARK: - Import

    /// Import Plist file via file picker, into the given profile
    func importPlistFile(into profile: Profile, replaceAll: Bool = true) async {
        do {
            // Datei auswählen
            guard let fileURL = try await importService.selectFileForImport() else {
                logger.info("Import abgebrochen")
                return
            }

            // Nur Plist erlauben
            guard fileURL.pathExtension.lowercased() == "plist" else {
                throw AppError.importUnsupportedFormat(fileURL.pathExtension)
            }

            // Datei parsen
            let parsedConfig = try FormatParser.parse(fileURL: fileURL)

            // Import durchführen
            try await performImport(parsedConfig: parsedConfig, into: profile, replaceAll: replaceAll)

            logger.info("Plist Import erfolgreich: \(parsedConfig.favorites.count) Items")

        } catch {
            handleError(error)
        }
    }

    /// Import JSON from string (copy/paste), into the given profile
    func importJSONString(_ jsonString: String, into profile: Profile, replaceAll: Bool = true) async {
        do {
            // Parse JSON string
            let parsedConfig = try FormatParser.parseJSONString(jsonString)

            // Import durchführen
            try await performImport(parsedConfig: parsedConfig, into: profile, replaceAll: replaceAll)

            logger.info("JSON Import erfolgreich: \(parsedConfig.favorites.count) Items")

        } catch {
            handleError(error)
        }
    }

    /// Shared import logic — scoped to one profile's base tree, never touches other profiles.
    private func performImport(parsedConfig: ParsedConfiguration, into profile: Profile, replaceAll: Bool) async throws {
        logger.info("Import gestartet: \(parsedConfig.favorites.count) Items, replaceAll=\(replaceAll)")

        guard let modelContext = modelContext else {
            logger.error("ModelContext nicht verfügbar")
            return
        }

        let profileID = profile.id

        // Option 1: Alles ersetzen (Delete all existing base-tree favorites of this profile)
        if replaceAll {
            let fetchDescriptor = FetchDescriptor<Favorite>(
                predicate: #Predicate { $0.profileID == profileID && $0.groupID == nil }
            )
            let existingFavorites = try modelContext.fetch(fetchDescriptor)

            for favorite in existingFavorites {
                modelContext.delete(favorite)
            }

            logger.info("Bestehende Favoriten gelöscht: \(existingFavorites.count)")
        }

        // Import parsed favorites
        importParsedFavorites(parsedConfig.favorites, parentID: nil, profileID: profileID, modelContext: modelContext)

        // Update this profile's toplevelName
        profile.toplevelName = parsedConfig.toplevelName

        // Save to database
        try modelContext.save()

        logger.info("Import erfolgreich abgeschlossen: \(parsedConfig.favorites.count) Items importiert")
    }

    /// Rekursiv Favoriten importieren (unterstützt Ordner)
    private func importParsedFavorites(_ parsedFavorites: [ParsedFavorite], parentID: UUID?, profileID: UUID, modelContext: ModelContext) {
        for parsedFav in parsedFavorites {
            let favorite = Favorite(
                name: parsedFav.name,
                url: parsedFav.url,
                parentID: parentID,
                order: parsedFav.order,
                profileID: profileID
            )

            modelContext.insert(favorite)

            // Wenn Ordner: Kinder rekursiv importieren
            if let children = parsedFav.children {
                importParsedFavorites(children, parentID: favorite.id, profileID: profileID, modelContext: modelContext)
            }
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
