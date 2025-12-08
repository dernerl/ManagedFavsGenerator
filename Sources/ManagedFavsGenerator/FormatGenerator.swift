import Foundation

enum FormatGenerator {
    
    // JSON for GPO (Windows onPrem) and Intune Settings Catalog (Windows)
    static func generateJSON(toplevelName: String, favorites: [Favorite]) -> String {
        var items: [[String: Any]] = []
        
        // First item: toplevel_name
        items.append(["toplevel_name": toplevelName])
        
        // Get root level items (no parent)
        let rootItems = favorites.filter { $0.parentID == nil }.sorted { $0.order < $1.order }
        
        for item in rootItems where !item.name.isEmpty {
            if item.isFolder {
                // Folder: name + children array
                let children = favorites.filter { $0.parentID == item.id }.sorted { $0.order < $1.order }
                var childrenArray: [[String: String]] = []
                
                for child in children where !child.name.isEmpty {
                    if let url = child.url, !url.isEmpty {
                        childrenArray.append([
                            "name": child.name,
                            "url": url
                        ])
                    }
                }
                
                items.append([
                    "name": item.name,
                    "children": childrenArray
                ])
            } else {
                // Regular favorite: name + url
                if let url = item.url, !url.isEmpty {
                    items.append([
                        "name": item.name,
                        "url": url
                    ])
                }
            }
        }
        
        // Use JSONSerialization for [String: Any] support
        guard let jsonData = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
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
        
        // Get root level items (no parent)
        let rootItems = favorites.filter { $0.parentID == nil }.sorted { $0.order < $1.order }
        
        for item in rootItems where !item.name.isEmpty {
            if item.isFolder {
                // Folder: children array FIRST, then name (Microsoft format)
                plistLines.append("\t\t<dict>")
                plistLines.append("\t\t\t<key>children</key>")
                plistLines.append("\t\t\t<array>")
                
                let children = favorites.filter { $0.parentID == item.id }.sorted { $0.order < $1.order }
                for child in children where !child.name.isEmpty {
                    if let url = child.url, !url.isEmpty {
                        plistLines.append("\t\t\t\t<dict>")
                        plistLines.append("\t\t\t\t\t<key>name</key>")
                        plistLines.append("\t\t\t\t\t<string>\(child.name.xmlEscaped)</string>")
                        plistLines.append("\t\t\t\t\t<key>url</key>")
                        plistLines.append("\t\t\t\t\t<string>\(url.xmlEscaped)</string>")
                        plistLines.append("\t\t\t\t</dict>")
                    }
                }
                
                plistLines.append("\t\t\t</array>")
                plistLines.append("\t\t\t<key>name</key>")
                plistLines.append("\t\t\t<string>\(item.name.xmlEscaped)</string>")
                plistLines.append("\t\t</dict>")
            } else {
                // Regular favorite: name + url
                if let url = item.url, !url.isEmpty {
                    plistLines.append("\t\t<dict>")
                    plistLines.append("\t\t\t<key>name</key>")
                    plistLines.append("\t\t\t<string>\(item.name.xmlEscaped)</string>")
                    plistLines.append("\t\t\t<key>url</key>")
                    plistLines.append("\t\t\t<string>\(url.xmlEscaped)</string>")
                    plistLines.append("\t\t</dict>")
                }
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
