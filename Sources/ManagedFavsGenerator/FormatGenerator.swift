import Foundation

enum FormatGenerator {
    
    // JSON for GPO (Windows onPrem) and Intune Settings Catalog (Windows)
    static func generateJSON(toplevelName: String, favorites: [Favorite]) -> String {
        var items: [[String: String]] = []
        
        // First item: toplevel_name
        items.append(["toplevel_name": toplevelName])
        
        // Only export favorites (not folders) at root level
        let rootFavorites = favorites.filter { !$0.isFolder && $0.parentID == nil }
        for favorite in rootFavorites where !favorite.name.isEmpty {
            if let url = favorite.url, !url.isEmpty {
                items.append([
                    "url": url,
                    "name": favorite.name
                ])
            }
        }
        
        // Use JSONEncoder with .withoutEscapingSlashes to prevent https:// -> https:\/\/
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        
        guard let jsonData = try? encoder.encode(items),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        
        return jsonString
    }
    
    // Plist for Intune macOS
    static func generatePlist(toplevelName: String, favorites: [Favorite]) -> String {
        var plistLines: [String] = []
        
        plistLines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        plistLines.append("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">")
        plistLines.append("<plist version=\"1.0\">")
        plistLines.append("<dict>")
        plistLines.append("\t<key>ManagedFavorites</key>")
        plistLines.append("\t<array>")
        
        // Toplevel name entry
        plistLines.append("\t\t<dict>")
        plistLines.append("\t\t\t<key>toplevel_name</key>")
        plistLines.append("\t\t\t<string>\(toplevelName.xmlEscaped)</string>")
        plistLines.append("\t\t</dict>")
        
        // Only export favorites (not folders) at root level
        let rootFavorites = favorites.filter { !$0.isFolder && $0.parentID == nil }
        for favorite in rootFavorites where !favorite.name.isEmpty {
            if let url = favorite.url, !url.isEmpty {
                plistLines.append("\t\t<dict>")
                plistLines.append("\t\t\t<key>name</key>")
                plistLines.append("\t\t\t<string>\(favorite.name.xmlEscaped)</string>")
                plistLines.append("\t\t\t<key>url</key>")
                plistLines.append("\t\t\t<string>\(url.xmlEscaped)</string>")
                plistLines.append("\t\t</dict>")
            }
        }
        
        plistLines.append("\t</array>")
        plistLines.append("</dict>")
        plistLines.append("</plist>")
        
        return plistLines.joined(separator: "\n")
    }
}

extension String {
    var xmlEscaped: String {
        self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
