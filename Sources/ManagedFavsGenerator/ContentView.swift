import SwiftUI
import SwiftData
import OSLog
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // Note: @Query is a SwiftData macro, not a GitHub user mention
    @Query(sort: \Favorite.createdAt) private var favorites: [Favorite]
    @State private var viewModel = FavoritesViewModel()
    @State private var showImportJSON = false
    @Environment(\.openWindow) private var openWindow
    
    /// Root level items (no parent)
    private var rootLevelItems: [Favorite] {
        favorites.filter { $0.parentID == nil }.sorted { $0.order < $1.order }
    }
    
    /// Get children of a folder
    private func childrenOf(_ folder: Favorite) -> [Favorite] {
        favorites.filter { $0.parentID == folder.id }.sorted { $0.order < $1.order }
    }
    
    /// Handle drop operation
    private func handleDrop(droppedIds: [String], toParent parentID: UUID?, atIndex index: Int) {
        guard let droppedId = droppedIds.first,
              let droppedUUID = UUID(uuidString: droppedId),
              let favorite = favorites.first(where: { $0.id == droppedUUID }) else {
            return
        }
        
        // Don't allow dropping a folder into itself
        if let parentID = parentID, parentID == favorite.id {
            return
        }
        
        // Don't allow dropping folders into other folders (only 1 level deep)
        if favorite.isFolder && parentID != nil {
            return
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewModel.moveFavorite(favorite, toParent: parentID, atIndex: index, allFavorites: favorites)
        }
    }
    
    var body: some View {
        ZStack {
            // Hidden helper view um First Responder zu aktivieren
            FirstResponderActivator()
                .frame(width: 0, height: 0)
                .hidden()
            
            HSplitView {
                // Left side: Input
                inputSection
                    .frame(minWidth: 400, maxWidth: 500)
                
                // Right side: Output
                outputSection
                    .frame(minWidth: 500)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Add Favorite
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.addFavorite()
                    }
                } label: {
                    Label("Add Favorite", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: [.command])
                .help("Add a new favorite (⌘N)")
                
                // Add Folder
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.addFolder()
                    }
                } label: {
                    Label("Add Folder", systemImage: "folder.badge.plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .help("Add a new folder (⌘⇧N)")
                
                Divider()
                
                // JSON Format Group
                Text("JSON:")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                // Import JSON (Copy/Paste)
                Button {
                    showImportJSON = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("i", modifiers: [.command])
                .help("Import JSON via Copy/Paste (⌘I)")
                
                // Copy JSON
                Button {
                    let json = FormatGenerator.generateJSON(
                        toplevelName: viewModel.toplevelName,
                        favorites: favorites
                    )
                    viewModel.copyToClipboard(json)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .help("Copy JSON to clipboard (⌘⇧C)")
                .disabled(favorites.isEmpty)
                
                Divider()
                
                // Plist Format Group
                Text("Plist:")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                // Import Plist (File)
                Button {
                    Task {
                        await viewModel.importPlistFile(replaceAll: true)
                    }
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .help("Import Plist file (⌘⇧I)")
                
                // Export Plist
                Button {
                    Task {
                        await viewModel.exportPlist(favorites: favorites)
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .keyboardShortcut("s", modifiers: [.command])
                .help("Export Plist file (⌘S)")
                .disabled(favorites.isEmpty)
            }
        }
        .onAppear {
            // ModelContext in ViewModel injizieren
            viewModel = FavoritesViewModel(modelContext: modelContext)
            
            // Window-Aktivierung beim View-Erscheinen
            // Der Hauptteil des Focus-Managements wird im AppDelegate erledigt
            Task { @MainActor in
                // Kurzer Delay, damit SwiftUI die View-Hierarchie aufbauen kann
                try? await Task.sleep(for: .milliseconds(100))
                
                NSApplication.shared.activate(ignoringOtherApps: true)
                
                if let window = NSApplication.shared.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
                    window.makeKeyAndOrderFront(nil)
                    window.makeFirstResponder(window.contentView)
                }
            }
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Ein unerwarteter Fehler ist aufgetreten")
        }
        .sheet(isPresented: $showImportJSON) {
            ImportJSONView { jsonString in
                Task {
                    await viewModel.importJSONString(jsonString, replaceAll: true)
                }
            }
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Favorites List
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Favorites")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Add and organize your favorites")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ScrollView {
                    VStack(spacing: 12) {
                        // Drop zone BEFORE first root item (always visible)
                        Color.clear
                            .frame(height: 20)
                            .dropDestination(for: String.self) { droppedIds, location in
                                handleDrop(droppedIds: droppedIds, toParent: nil, atIndex: 0)
                                return true
                            }
                        
                        // Root level items (no parent)
                        ForEach(Array(rootLevelItems.enumerated()), id: \.element.id) { index, item in
                            if item.isFolder {
                                // Folder with children
                                VStack(spacing: 0) {
                                    DisclosureGroup {
                                        VStack(spacing: 12) {
                                            // Drop zone at START of folder (for first position)
                                            Color.clear
                                                .frame(height: 20)
                                                .dropDestination(for: String.self) { droppedIds, location in
                                                    handleDrop(droppedIds: droppedIds, toParent: item.id, atIndex: 0)
                                                    return true
                                                }
                                            
                                            ForEach(Array(childrenOf(item).enumerated()), id: \.element.id) { childIndex, child in
                                                FavoriteRowView(
                                                    favorite: child,
                                                    onRemove: {
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                            viewModel.removeFavorite(child)
                                                        }
                                                    }
                                                )
                                                .padding(.leading, 16)
                                                .transition(.scale.combined(with: .opacity))
                                                .dropDestination(for: String.self) { droppedIds, location in
                                                    // Drop AFTER this child
                                                    handleDrop(droppedIds: droppedIds, toParent: item.id, atIndex: childIndex + 1)
                                                    return true
                                                }
                                            }
                                            
                                            // Drop zone at END of folder (when folder is empty or after last item)
                                            if childrenOf(item).isEmpty {
                                                Color.clear
                                                    .frame(height: 40)
                                                    .dropDestination(for: String.self) { droppedIds, location in
                                                        handleDrop(droppedIds: droppedIds, toParent: item.id, atIndex: 0)
                                                        return true
                                                    }
                                            }
                                        }
                                    } label: {
                                        FolderRowView(
                                            folder: item,
                                            onRemove: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    viewModel.removeFavorite(item)
                                                }
                                            },
                                            onAddChild: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    viewModel.addFavorite(parentID: item.id)
                                                }
                                            }
                                        )
                                    }
                                    .disclosureGroupStyle(.automatic)
                                }
                            } else {
                                // Regular favorite
                                FavoriteRowView(
                                    favorite: item,
                                    onRemove: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.removeFavorite(item)
                                        }
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                                .dropDestination(for: String.self) { droppedIds, location in
                                    // Drop after this favorite
                                    handleDrop(droppedIds: droppedIds, toParent: nil, atIndex: index + 1)
                                    return true
                                }
                            }
                        }
                        
                        // Drop zone at end of root level
                        Color.clear
                            .frame(height: 40)
                            .dropDestination(for: String.self) { droppedIds, location in
                                handleDrop(droppedIds: droppedIds, toParent: nil, atIndex: rootLevelItems.count)
                                return true
                            }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: favorites.count)
                }
            }
            
            if favorites.isEmpty {
                ContentUnavailableView {
                    Label("No Favorites", systemImage: "star.slash")
                } description: {
                    Text("Press ⌘N or click Add to create your first favorite")
                        .foregroundStyle(.secondary)
                } actions: {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.addFavorite()
                        }
                    } label: {
                        Label("Add Favorite", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .padding()
    }
    
    // MARK: - Output Section
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Generated Outputs")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Ready to copy or export")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if viewModel.showCopiedFeedback {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .imageScale(.medium)
                    Text("Copied to clipboard!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showCopiedFeedback)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // GPO / Intune Windows
                    OutputFormatCard(
                        title: "GPO & Intune Windows (JSON)",
                        subtitle: "For onPrem GPO and Intune Settings Catalog",
                        content: FormatGenerator.generateJSON(
                            toplevelName: viewModel.toplevelName,
                            favorites: favorites
                        )
                    )
                    
                    // Intune macOS
                    OutputFormatCard(
                        title: "Intune macOS (Plist)",
                        subtitle: "For Intune Device Configuration Profile",
                        content: FormatGenerator.generatePlist(
                            toplevelName: viewModel.toplevelName,
                            favorites: favorites
                        )
                    )
                }
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct FavoriteRowView: View {
    @Bindable var favorite: Favorite
    let onRemove: () -> Void
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var isFaviconHovered = false  // Separate hover state for favicon
    @AppStorage("faviconProvider") private var faviconProvider: FaviconProvider = .google
    
    // Cached favicon URL - only computed when URL or provider changes
    @State private var cachedFaviconURL: URL?
    
    private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "Favicons")
    
    /// Computes the favicon URL for the current favorite URL and provider
    private func computeFaviconURL() -> URL? {
        guard let urlString = favorite.url,
              !urlString.isEmpty,
              let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        
        // Remove www. prefix if present
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let faviconURL = faviconProvider.faviconURL(for: domain)
        
        // Log which provider is being used (public for debugging)
        logger.info("Loading favicon for '\(domain, privacy: .public)' using \(faviconProvider.rawValue, privacy: .public) provider: \(faviconURL?.absoluteString ?? "nil", privacy: .public)")
        
        return faviconURL
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Favicon + Title
                HStack(spacing: 8) {
                    // Favicon with hover effects
                    AsyncImage(url: cachedFaviconURL) { phase in
                        Group {
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure, .empty:
                                Image(systemName: "globe")
                                    .foregroundStyle(.secondary)
                                    .imageScale(.medium)
                            @unknown default:
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .frame(width: 20, height: 20)
                    }
                    .scaleEffect(isFaviconHovered ? 1.2 : 1.0)  // Scale to 1.2x on hover
                    .shadow(
                        color: isFaviconHovered ? .blue.opacity(0.3) : .clear,  // Glow effect
                        radius: isFaviconHovered ? 4 : 0
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFaviconHovered)  // Smooth spring animation
                    .onHover { hovering in
                        isFaviconHovered = hovering
                    }
                    
                    Label("Favorite", systemImage: "star.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1.0 : 0.6)
                .help("Delete this favorite")
            }
            
            AppKitTextField(
                text: $favorite.name,
                placeholder: "Name"
            )
            .frame(height: 22)
            
            AppKitTextField(
                text: Binding(
                    get: { favorite.url ?? "" },
                    set: { favorite.url = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "URL"
            )
            .frame(height: 22)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.08), radius: isHovering ? 12 : 8, y: isHovering ? 6 : 4)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .opacity(isDragging ? 0.5 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .onHover { hovering in
            isHovering = hovering
        }
        .draggable(favorite.id.uuidString) {
            // Drag preview
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(favorite.name)
                        .font(.headline)
                }
                if let url = favorite.url {
                    Text(url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 8)
            .onAppear { isDragging = true }
            .onDisappear { isDragging = false }
        }
        .onAppear {
            // Compute favicon URL when view first appears
            cachedFaviconURL = computeFaviconURL()
        }
        .onChange(of: favorite.url) { oldValue, newValue in
            // Recompute favicon URL when favorite URL changes
            cachedFaviconURL = computeFaviconURL()
        }
        .onChange(of: faviconProvider) { oldValue, newValue in
            // Recompute favicon URL when provider changes
            cachedFaviconURL = computeFaviconURL()
        }
    }
}

struct OutputFormatCard: View {
    let title: String
    let subtitle: String
    let content: String
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    if !content.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .imageScale(.small)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxHeight: 200)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovering ? 0.15 : 0.1), radius: isHovering ? 14 : 10, y: isHovering ? 7 : 5)
        .scaleEffect(isHovering ? 1.005 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: Favorite.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        // Sample data
        let context = container.mainContext
        let sample1 = Favorite(name: "Google", url: "https://google.com")
        let sample2 = Favorite(name: "Apple", url: "https://apple.com")
        
        context.insert(sample1)
        context.insert(sample2)
        
        return container
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()
