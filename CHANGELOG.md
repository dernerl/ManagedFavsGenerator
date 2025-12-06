# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
