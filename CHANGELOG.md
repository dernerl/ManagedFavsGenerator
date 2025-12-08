# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2024-12-07

### Added
- **Folder Support** - Hierarchical organization of favorites (#4)
  - Create folders with disclosure groups
  - Drag & drop favorites between root and folders
  - Reorder items within same level
  - Export with `children` arrays in JSON/Plist
  - One-level deep hierarchy (folders cannot contain folders)
- **Favicon Provider Settings** - Choose between Google and DuckDuckGo (#3)
  - Appearance section in Settings (⌘,)
  - Google: More reliable, comprehensive coverage
  - DuckDuckGo: Privacy-focused, no tracking
  - OSLog for debugging which provider is used
- **GitHub Issue Templates** - Consistent naming conventions
  - `feat:` prefix for feature requests
  - `fix:` prefix for bug reports
  - `docs:` prefix for documentation
  - Form-based templates with required fields
  - Blank issues disabled

### Changed
- **TopLevel Name** moved to Settings from main view
  - Cleaner main UI
  - Avoids drag & drop conflicts
  - Semantically correct location
- **Section Headers** - Consistent styling across Favorites and Generated Outputs
  - `.title2` font with bold weight
  - Subtitle with description
  - Unified spacing

### Fixed
- **SwiftData Migration** - Order field with default value (0) for automatic migration
- **Plist Format** - `children` key before `name` key (Microsoft specification)
- **Drag & Drop** - Multiple improvements
  - Drop zone before first item
  - Index-based dropping for accurate positioning
  - Validation: Folders cannot be nested
  - Validation: Folders cannot drop into themselves

### Technical
- New `FaviconProvider` enum with URL generation
- `moveFavorite()` method in ViewModel for drag & drop logic
- `FolderRowView` component for folder display
- Enhanced `FormatGenerator` with children array support
- OSLog with "Favicons" category for debugging
- AppStorage for persistent Settings

### Documentation
- README: Debugging section with log stream command
- README: Favicon provider verification guide
- AGENTS.md: Issue template guidelines
- Pre-commit hooks for code quality

## [1.0.1] - 2024-12-06

### Fixed
- Added `.gitattributes` to prevent GitHub from interpreting Swift macros as user mentions
- Added clarifying comments for `@Query` and `@Model` Swift macros
- Resolves false contributor attribution to GitHub users @query and @model

### Documentation
- Added Semantic Versioning guidelines to AGENTS.md
- Clarified version bump strategy (MAJOR.MINOR.PATCH)

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
