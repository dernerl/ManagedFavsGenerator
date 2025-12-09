# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2024-12-19

### Added
- **Folder Support** - Hierarchical organization of favorites (#7)
  - Create folders with disclosure groups
  - Drag & drop favorites between root and folders
  - Reorder items within same level
  - Export with `children` arrays in JSON/Plist
  - One-level deep hierarchy (folders cannot contain folders)
  - Visual folder icon with badge
- **Favicon Display** - Visual website icons for favorites
  - Automatic favicon loading from URLs
  - Fallback to star icon when unavailable
  - 16x16pt size for compact display
  - Async loading with placeholder
- **Favicon Provider Settings** - Choose between Google and DuckDuckGo (#10)
  - Settings panel (⌘,) with Appearance section
  - Google: More reliable, comprehensive coverage
  - DuckDuckGo: Privacy-focused, no tracking
  - OSLog for debugging provider usage
- **Favicon Hover Effects** - Smooth animations on interaction (#2)
  - Scale animation on hover (1.0 → 1.15)
  - Subtle shadow effect
  - Spring animation with bounce
  - Separate hover state for favicon only
- **Import Configuration** - Import existing JSON and Plist configurations (#12)
  - **JSON Import via Copy/Paste** (⌘I)
    - Paste JSON directly into dialog
    - Automatic format detection
  - **Plist Import via File Selection** (⌘⇧I)
    - NSOpenPanel for file selection
    - Supports full Plist files and fragments
    - Auto-wraps Intune export fragments
  - Replace all existing favorites on import
  - Folder structure preservation
  - Toplevel name extraction and update
- **Toolbar Grouping** - Improved button organization (#13)
  - "JSON:" and "Plist:" text labels visible
  - Actions grouped by format
  - Consistent icons (↓ Import, ↑ Export)
  - Cleaner visual hierarchy
- **GitHub Issue Templates** - Consistent naming conventions
  - `feat:` prefix for feature requests
  - `fix:` prefix for bug reports
  - `docs:` prefix for documentation
  - Form-based templates with required fields

### Fixed
- **GitHub Macro Mentions** - Prevent @Query/@Model attribution (#1)
  - Added `.gitattributes` file
  - Added clarifying comments for Swift macros
- **JSON Export** - Remove escaped slashes in output
  - Clean JSON without unnecessary escaping
  - Better readability
- **Toplevel Name Persistence** - Settings changes now saved
  - SwiftData persistence for toplevel name
  - Changes reflected immediately in exports
- **Favicon Rendering Stability** - Improved async loading
  - Better error handling
  - Smoother placeholder transitions
- **Favicon Performance** - Cache URLs to prevent recomputation (#11)
  - Favicon URLs cached with @State
  - Only recomputed on URL or provider changes
  - No more recomputation on hover/focus events
  - Reduced CPU usage and log spam

### Changed
- **TopLevel Name** moved to Settings from main view
  - Cleaner main UI
  - Avoids drag & drop conflicts
  - Semantically correct location
- **Section Headers** - Consistent styling across views
  - `.title2` font with bold weight
  - Subtitle with description
  - Unified spacing
- **Toolbar Layout** - Format-based grouping
  - `[Add] [Folder] | JSON: [Import] [Copy] | Plist: [Import] [Export]`
  - Shorter button labels
  - Better visual organization

### Technical
- New `FaviconProvider` enum with URL generation
- New `FormatParser` for JSON/Plist parsing
- New `ImportService` with NSOpenPanel
- New `ImportJSONView` - SwiftUI import dialog
- `moveFavorite()` method for drag & drop logic
- `FolderRowView` component for folder display
- Enhanced `FormatGenerator` with children array support
- Extended `AppError` with import-specific errors
- `MockImportService` for unit testing
- SwiftData migration with `order` field
- OSLog with "Favicons" category
- AppStorage for persistent Settings
- Plist fragment detection and wrapping
- Favicon URL caching with lifecycle handlers

### Documentation
- README: Debugging section with log stream command
- README: Favicon provider verification guide
- README: Gatekeeper bypass instructions
- AGENTS.md: Issue template guidelines
- AGENTS.md: Semantic Versioning strategy

## [1.0.0] - 2024-12-06

### Added
- Initial release
- SwiftUI-based native macOS app
- SwiftData for persistent storage
- JSON format generation (Windows/GPO)
- Plist format generation (macOS/Intune)
- Keyboard shortcuts (⌘N, ⌘S, ⌘⇧C)
- Toolbar with primary actions
- Settings panel (⌘,)
- Liquid-Glass design with Materials
- Smooth animations and transitions
- Hover effects on cards
- Empty state with call-to-action
- Clipboard support
- File export functionality

### Technical
- MVVM architecture with Service Layer
- Dependency Injection for testability
- Swift 6 concurrency compliance
- HIG-compliant design
- @Model for SwiftData entities
- @Query for automatic UI updates
- Protocol-based services

---

## Categories

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security improvements
- **Technical** - Internal improvements
