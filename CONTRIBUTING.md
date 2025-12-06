# Contributing to Managed Favs Generator

Thank you for your interest in contributing! 🎉

## Code of Conduct

Be respectful and constructive. This is a professional tool for IT administrators.

## How to Contribute

### Reporting Bugs

1. **Check existing issues** to avoid duplicates
2. **Use the issue template** (if available)
3. **Include details**:
   - macOS version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

### Suggesting Features

1. **Open an issue** with the `enhancement` label
2. **Describe the use case** - Why would IT admins need this?
3. **Provide examples** - How would it work?

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Follow the code style** (see AGENTS.md)
4. **Write tests** if applicable
5. **Update documentation** if needed
6. **Commit with clear messages**:
   ```
   feat: Add drag & drop for favorites
   fix: Resolve clipboard issue on macOS 15
   docs: Update deployment guide
   ```
7. **Push and create PR**: Describe what and why

## Development Setup

### Requirements
- macOS 15.0+ (Sequoia)
- Xcode 16+
- Swift 6.0+

### Build & Run
```bash
git clone <your-fork>
cd ManagedFavsGenerator
swift build
.build/debug/ManagedFavsGenerator
```

### Code Standards

See **[AGENTS.md](../AGENTS.md)** for:
- MVVM architecture guidelines
- SwiftData best practices
- HIG compliance requirements
- Liquid-Glass design principles

### Key Principles

1. **MVVM Architecture** - Service Layer for external access
2. **SwiftData** - All data must be persistent
3. **HIG Compliant** - Toolbar, Shortcuts, Settings
4. **Liquid-Glass** - Materials instead of static colors
5. **Swift 6** - No concurrency warnings
6. **Testable** - Use Dependency Injection

## Testing

### Manual Testing
1. Add favorites
2. Restart app → Data persists?
3. Export → File created?
4. Copy → Clipboard works?
5. Settings → Preferences saved?

### Unit Tests (Coming Soon)
```bash
swift test
```

## Project Structure

```
ManagedFavsGenerator/
├── Sources/ManagedFavsGenerator/
│   ├── Services/          # External access (Clipboard, File)
│   ├── ViewModel          # Business logic
│   ├── Views              # SwiftUI views
│   └── Models             # SwiftData models
```

## Documentation

- **README.md** - User-facing documentation
- **AGENTS.md** - Developer guidelines
- **Code comments** - Use `///` for public APIs

## Review Process

1. **Automated checks** (when set up):
   - Build success
   - Swift 6 compliance
   - Code style

2. **Manual review**:
   - Code quality
   - Architecture alignment
   - User experience

3. **Testing**:
   - Manual testing by reviewer
   - No regressions

## Questions?

Open an issue or discussion! We're here to help.

---

**Thank you for contributing!** 🚀
