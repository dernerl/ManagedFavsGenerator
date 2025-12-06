import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // Note: @Query is a SwiftData macro, not a GitHub user mention
    @Query(sort: \Favorite.createdAt) private var favorites: [Favorite]
    @State private var viewModel = FavoritesViewModel()
    @Environment(\.openWindow) private var openWindow
    @AppStorage("defaultToplevelName") private var defaultToplevelName = "managedFavs"
    
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
                
                Divider()
                
                // Copy JSON
                Button {
                    let json = FormatGenerator.generateJSON(
                        toplevelName: viewModel.toplevelName,
                        favorites: favorites
                    )
                    viewModel.copyToClipboard(json)
                } label: {
                    Label("Copy JSON", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .help("Copy JSON to clipboard (⌘⇧C)")
                .disabled(favorites.isEmpty)
                
                // Export Plist
                Button {
                    Task {
                        await viewModel.exportPlist(favorites: favorites)
                    }
                } label: {
                    Label("Export Plist", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: [.command])
                .help("Export Plist file (⌘S)")
                .disabled(favorites.isEmpty)
            }
        }
        .onAppear {
            // ModelContext in ViewModel injizieren
            viewModel = FavoritesViewModel(modelContext: modelContext)
            
            // Default Toplevel Name aus Settings laden
            if viewModel.toplevelName == "managedFavs" {
                viewModel.toplevelName = defaultToplevelName
            }
            
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
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Toplevel Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Toplevel Name")
                    .font(.headline)
                AppKitTextField(
                    text: $viewModel.toplevelName,
                    placeholder: "e.g., managedFavs"
                )
                .frame(height: 22)
            }
            
            Divider()
            
            // Favorites List
            VStack(alignment: .leading, spacing: 8) {
                Text("Favorites")
                    .font(.headline)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(favorites) { favorite in
                            FavoriteRowView(
                                favorite: favorite,
                                onRemove: { 
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.removeFavorite(favorite)
                                    }
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
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
    
    /// Generates the favicon URL using Google's favicon service
    private var faviconURL: URL? {
        guard !favorite.url.isEmpty,
              let url = URL(string: favorite.url),
              let domain = url.host else {
            return nil
        }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=32")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Favicon + Title
                HStack(spacing: 8) {
                    // Favicon
                    AsyncImage(url: faviconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        case .failure, .empty:
                            Image(systemName: "globe")
                                .foregroundStyle(.secondary)
                                .frame(width: 20, height: 20)
                                .imageScale(.medium)
                        @unknown default:
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 20, height: 20)
                        }
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
                text: $favorite.url,
                placeholder: "URL"
            )
            .frame(height: 22)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.08), radius: isHovering ? 12 : 8, y: isHovering ? 6 : 4)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
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
