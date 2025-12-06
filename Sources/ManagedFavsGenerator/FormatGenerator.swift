import Foundation

enum FormatGenerator {
    
    // JSON for GPO (Windows onPrem) and Intune Settings Catalog (Windows)
    static func generateJSON(toplevelName: String, favorites: [Favorite]) -> String {
        var items: [[String: String]] = []
        
        // First item: toplevel_name
        items.append(["toplevel_name": toplevelName])
        
        // Favorites
        for favorite in favorites where !favorite.name.isEmpty && !favorite.url.isEmpty {
            items.append([
                "url": favorite.url,
                "name": favorite.name
            ])
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted, .sortedKeys]),
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
        
        // Favorites
        for favorite in favorites where !favorite.name.isEmpty && !favorite.url.isEmpty {
            plistLines.append("\t\t<dict>")
            plistLines.append("\t\t\t<key>name</key>")
            plistLines.append("\t\t\t<string>\(favorite.name.xmlEscaped)</string>")
            plistLines.append("\t\t\t<key>url</key>")
            plistLines.append("\t\t\t<string>\(favorite.url.xmlEscaped)</string>")
            plistLines.append("\t\t</dict>")
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
