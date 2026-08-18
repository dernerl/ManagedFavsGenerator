import SwiftUI
import SwiftData
import OSLog
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // Note: @Query is a SwiftData macro, not a GitHub user mention
    @Query(sort: \Favorite.createdAt) private var favorites: [Favorite]
    @Query(sort: \TargetGroup.order) private var targetGroups: [TargetGroup]
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @State private var viewModel = FavoritesViewModel()
    @State private var showImportJSON = false
    @State private var selectedLeftTab: LeftTab = .favorites
    @State private var selectedOutput: OutputTab = .json
    @State private var renamingProfile: Profile?
    @State private var renameText: String = ""
    @AppStorage("activeProfileID") private var activeProfileIDString: String = ""
    @Environment(\.openWindow) private var openWindow

    enum LeftTab: Hashable {
        case favorites, targetGroups
    }

    enum OutputTab: Hashable {
        case json, plist, cloudPolicy
        case group(UUID)
    }

    // MARK: - Profile scoping

    private var activeProfile: Profile? {
        if let id = UUID(uuidString: activeProfileIDString), let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.sorted(by: { $0.order < $1.order }).first
    }

    private var profileFavorites: [Favorite] {
        guard let activeProfile else { return [] }
        return favorites.filter { $0.profileID == activeProfile.id }
    }

    private var profileTargetGroups: [TargetGroup] {
        guard let activeProfile else { return [] }
        return targetGroups.filter { $0.profileID == activeProfile.id }.sorted { $0.order < $1.order }
    }

    /// Base tree only — excludes items that belong to a Target Group.
    private var baseFavorites: [Favorite] {
        profileFavorites.filter { $0.groupID == nil }
    }

    /// Root level items (no parent, no target group) within the active profile
    private var rootLevelItems: [Favorite] {
        baseFavorites.filter { $0.parentID == nil }.sorted { $0.order < $1.order }
    }

    /// Get children of a folder
    private func childrenOf(_ folder: Favorite) -> [Favorite] {
        profileFavorites.filter { $0.parentID == folder.id }.sorted { $0.order < $1.order }
    }

    /// Favorites belonging to a target group (flat, no sub-folders)
    private func groupFavorites(_ group: TargetGroup) -> [Favorite] {
        profileFavorites.filter { $0.groupID == group.id }
    }

    private var nonEmptyGroups: [TargetGroup] {
        profileTargetGroups.filter { !groupFavorites($0).isEmpty }
    }

    /// Handle drop operation
    private func handleDrop(droppedIds: [String], toParent parentID: UUID?, atIndex index: Int) {
        guard let droppedId = droppedIds.first,
              let droppedUUID = UUID(uuidString: droppedId),
              let favorite = profileFavorites.first(where: { $0.id == droppedUUID }) else {
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
            viewModel.moveFavorite(favorite, toParent: parentID, atIndex: index, allFavorites: profileFavorites)
        }
    }

    // MARK: - Migration

    /// First-run migration: earlier versions had no Profile concept. Create a default one
    /// and adopt any orphaned favorites/groups (profileID == nil) into it.
    private func runMigrationIfNeeded() {
        guard profiles.isEmpty else { return }

        let savedName = UserDefaults.standard.string(forKey: "defaultToplevelName") ?? "managedFavs"
        let profile = Profile(name: "Default", toplevelName: savedName, order: 0)
        modelContext.insert(profile)

        for favorite in favorites where favorite.profileID == nil {
            favorite.profileID = profile.id
        }
        for group in targetGroups where group.profileID == nil {
            group.profileID = profile.id
        }

        do {
            try modelContext.save()
        } catch {
            Logger(subsystem: "ManagedFavsGenerator", category: "Migration").error("Migration fehlgeschlagen: \(error.localizedDescription)")
        }

        activeProfileIDString = profile.id.uuidString
    }

    var body: some View {
        ZStack {
            // Hidden helper view um First Responder zu aktivieren
            FirstResponderActivator()
                .frame(width: 0, height: 0)
                .hidden()

            HStack(spacing: 0) {
                profileRail

                Divider()

                VStack(spacing: 0) {
                    HSplitView {
                        // Left side: Input
                        inputSection
                            .frame(minWidth: 400, maxWidth: 500)

                        // Right side: Output
                        outputSection
                            .frame(minWidth: 500)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Text(activeProfile?.name ?? "")
                    .font(.headline)
            }
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    showImportJSON = true
                } label: {
                    Label("Import JSON", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("i", modifiers: [.command])
                .help("Import JSON via Copy/Paste (⌘I)")
                .disabled(activeProfile == nil)

                Button {
                    guard let activeProfile else { return }
                    Task {
                        await viewModel.importPlistFile(into: activeProfile, replaceAll: true)
                    }
                } label: {
                    Label("Import Plist", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .help("Import Plist file (⌘⇧I)")
                .disabled(activeProfile == nil)
            }
        }
        .onAppear {
            // ModelContext in ViewModel injizieren
            viewModel = FavoritesViewModel(modelContext: modelContext)

            runMigrationIfNeeded()

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
        .onChange(of: nonEmptyGroups.map(\.id)) { _, ids in
            if case .group(let id) = selectedOutput, !ids.contains(id) {
                selectedOutput = .json
            }
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Ein unerwarteter Fehler ist aufgetreten")
        }
        .alert("Rename Profile", isPresented: Binding(
            get: { renamingProfile != nil },
            set: { if !$0 { renamingProfile = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renamingProfile = nil }
            Button("Save") {
                if let profile = renamingProfile, !renameText.trimmingCharacters(in: .whitespaces).isEmpty {
                    profile.name = renameText
                    try? modelContext.save()
                }
                renamingProfile = nil
            }
        }
        .sheet(isPresented: $showImportJSON) {
            ImportJSONView { jsonString in
                guard let activeProfile else { return }
                Task {
                    await viewModel.importJSONString(jsonString, into: activeProfile, replaceAll: true)
                }
            }
        }
    }

    // MARK: - Profile Rail

    private var profileRail: some View {
        VStack(spacing: 14) {
            ForEach(profiles.sorted(by: { $0.order < $1.order })) { profile in
                profileChip(profile)
            }

            Spacer()

            Button {
                if let newProfile = viewModel.addProfile() {
                    activeProfileIDString = newProfile.id.uuidString
                }
            } label: {
                Image(systemName: "plus")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                            .foregroundStyle(.tertiary)
                    )
            }
            .buttonStyle(.plain)
            .help("Add Profile")
        }
        .padding(.vertical, 18)
        .frame(width: 76)
        .background(.thinMaterial)
    }

    private func profileChip(_ profile: Profile) -> some View {
        let isActive = profile.id == activeProfile?.id
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Circle()
                    .strokeBorder(isActive ? Color.accentColor : .clear, lineWidth: 2)
                    .frame(width: 40, height: 40)
                Text(initials(for: profile.name))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)
            }
            Text(profile.name)
                .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
        }
        .frame(width: 64)
        .contentShape(Rectangle())
        .onTapGesture {
            activeProfileIDString = profile.id.uuidString
        }
        .contextMenu {
            Button("Rename…") {
                renamingProfile = profile
                renameText = profile.name
            }
            if profiles.count > 1 {
                Button("Delete", role: .destructive) {
                    let wasActive = activeProfile?.id == profile.id
                    let fallback = profiles.first(where: { $0.id != profile.id })?.id
                    viewModel.removeProfile(profile, favorites: favorites, groups: targetGroups)
                    if wasActive {
                        activeProfileIDString = fallback?.uuidString ?? ""
                    }
                }
            }
        }
    }

    private func initials(for name: String) -> String {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Favorites")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)

            Picker("", selection: $selectedLeftTab) {
                Text("Favorites").tag(LeftTab.favorites)
                Text(profileTargetGroups.isEmpty ? "Target Groups" : "Target Groups · \(profileTargetGroups.count)")
                    .tag(LeftTab.targetGroups)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .padding(.horizontal)
            .padding(.top, 12)

            switch selectedLeftTab {
            case .favorites:
                favoritesSubtitleRow
                favoritesListScroll
            case .targetGroups:
                targetGroupsSubtitleRow
                targetGroupsListScroll
            }
        }
    }

    private var favoritesSubtitleRow: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("Add and organize your favorites")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.addFavorite(profileID: activeProfile?.id)
                    }
                } label: {
                    Label("Add Favorite", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: [.command])
                .help("Add a new favorite (⌘N)")

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.addFolder(profileID: activeProfile?.id)
                    }
                } label: {
                    Label("Add Folder", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .help("Add a new folder (⌘⇧N)")
            }
            .fixedSize()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var favoritesListScroll: some View {
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
                                            viewModel.addFavorite(parentID: item.id, profileID: activeProfile?.id)
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

                if rootLevelItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Favorites", systemImage: "star.slash")
                    } description: {
                        Text("Press ⌘N or click Add Favorite to create your first favorite")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: favorites.count)
        }
    }

    private var targetGroupsSubtitleRow: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("Extra favorites for a specific audience, exported alongside the base set")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.addTargetGroup(profileID: activeProfile?.id)
                }
            } label: {
                Label("Add Group", systemImage: "person.badge.plus")
            }
            .buttonStyle(.bordered)
            .fixedSize()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var targetGroupsListScroll: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(profileTargetGroups) { group in
                    TargetGroupCardView(
                        group: group,
                        items: groupFavorites(group),
                        onAddItem: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.addGroupFavorite(groupID: group.id, profileID: activeProfile?.id)
                            }
                        },
                        onRemoveItem: { item in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.removeFavorite(item)
                            }
                        },
                        onRemoveGroup: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.removeTargetGroup(group, favorites: profileFavorites)
                            }
                        }
                    )
                }

                if profileTargetGroups.isEmpty {
                    ContentUnavailableView {
                        Label("No Target Groups", systemImage: "person.2.slash")
                    } description: {
                        Text("Add a group for one audience's extra favorites")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Output Section

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Generated Outputs")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)

            Picker("", selection: $selectedOutput) {
                Text("JSON").tag(OutputTab.json)
                Text("Plist").tag(OutputTab.plist)
                Text("Cloud Policy").tag(OutputTab.cloudPolicy)
                ForEach(nonEmptyGroups) { group in
                    Text(group.name).tag(OutputTab.group(group.id))
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .padding(.horizontal)
            .padding(.top, 12)

            HStack(alignment: .center, spacing: 16) {
                Text(selectedOutputSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    if selectedOutput == .plist {
                        Button {
                            Task {
                                await viewModel.exportPlist(
                                    favorites: baseFavorites,
                                    toplevelName: activeProfile?.toplevelName ?? "managedFavs"
                                )
                            }
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .keyboardShortcut("s", modifiers: [.command])
                        .help("Export Plist file (⌘S)")
                        .disabled(baseFavorites.isEmpty)
                    }

                    Button {
                        viewModel.copyToClipboard(selectedOutputContent)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .help("Copy to clipboard (⌘⇧C)")
                    .disabled(selectedOutputContent.isEmpty)
                }
                .fixedSize()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

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
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showCopiedFeedback)
            }

            ScrollView {
                Text(selectedOutputContent)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var selectedOutputSubtitle: String {
        switch selectedOutput {
        case .json:
            return "For onPrem GPO and Intune Settings Catalog. Device-wide — every profile on the machine gets this set."
        case .plist:
            return "For an Intune Device Configuration Profile. Device-wide — every profile on the machine gets this set."
        case .cloudPolicy:
            return "Paste as the ManagedFavorites value of a Cloud configuration policy (M365 Admin Center → Settings → Microsoft Edge). Per-profile and cross-platform — a GPO or Intune device profile still wins if also present on the device."
        case .group(let id):
            guard let group = nonEmptyGroups.first(where: { $0.id == id }) else { return "" }
            return group.includeBase
                ? "Base set plus \"\(group.name)\" as a subfolder. Assign as an additive, lower-priority Cloud policy."
                : "Replaces the base set entirely for \"\(group.name)\". Assign as the highest-priority Cloud policy — ManagedFavorites does not merge across policies."
        }
    }

    private var selectedOutputContent: String {
        let toplevelName = activeProfile?.toplevelName ?? "managedFavs"
        switch selectedOutput {
        case .json:
            return FormatGenerator.generateJSON(toplevelName: toplevelName, favorites: baseFavorites)
        case .plist:
            return FormatGenerator.generatePlist(toplevelName: toplevelName, favorites: baseFavorites)
        case .cloudPolicy:
            return FormatGenerator.generateJSON(toplevelName: toplevelName, favorites: baseFavorites)
        case .group(let id):
            guard let group = nonEmptyGroups.first(where: { $0.id == id }) else { return "" }
            let items = groupFavorites(group)
            return group.includeBase
                ? FormatGenerator.generateJSON(toplevelName: toplevelName, favorites: baseFavorites, appending: group, groupFavorites: items)
                : FormatGenerator.generateJSON(toplevelName: group.name, favorites: items)
        }
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

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: Favorite.self, TargetGroup.self, Profile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        // Sample data
        let context = container.mainContext
        let profile = Profile(name: "Default", order: 0)
        context.insert(profile)
        let sample1 = Favorite(name: "Google", url: "https://google.com", profileID: profile.id)
        let sample2 = Favorite(name: "Apple", url: "https://apple.com", profileID: profile.id)

        context.insert(sample1)
        context.insert(sample2)

        return container
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()
