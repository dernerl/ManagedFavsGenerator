import Foundation

/// Favicon service provider
enum FaviconProvider: String, CaseIterable, Identifiable, Codable {
    case google = "Google"
    case duckduckgo = "DuckDuckGo"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .duckduckgo:
            return "DuckDuckGo (Privacy)"
        }
    }
    
    /// Description for settings
    var description: String {
        switch self {
        case .google:
            return "More reliable, comprehensive coverage"
        case .duckduckgo:
            return "Privacy-focused, no tracking"
        }
    }
    
    /// Generate favicon URL for a given domain
    func faviconURL(for domain: String) -> URL? {
        switch self {
        case .google:
            return URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=32")
        case .duckduckgo:
            return URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico")
        }
    }
}
