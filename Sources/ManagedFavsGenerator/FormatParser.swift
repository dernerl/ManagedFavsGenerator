import Foundation
import OSLog

private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "FormatParser")

/// Struktur für geparste Daten (intern)
struct ParsedConfiguration {
    var toplevelName: String
    var favorites: [ParsedFavorite]
}

struct ParsedFavorite {
    var name: String
    var url: String?
    var children: [ParsedFavorite]?
    var order: Int
}

enum FormatParser {
    
    // MARK: - Main Entry Point
    
    /// Parse JSON or Plist file and return structured data
    static func parse(fileURL: URL) throws -> ParsedConfiguration {
        let data = try Data(contentsOf: fileURL)
        
        switch fileURL.pathExtension.lowercased() {
        case "json":
            return try parseJSON(data: data)
        case "plist":
            return try parsePlist(data: data)
        default:
            throw AppError.importUnsupportedFormat(fileURL.pathExtension)
        }
    }
    
    /// Parse JSON from string (for copy/paste)
    static func parseJSONString(_ jsonString: String) throws -> ParsedConfiguration {
        guard let data = jsonString.data(using: .utf8) else {
            throw AppError.importInvalidFormat("JSON-String konnte nicht in Data konvertiert werden")
        }
        return try parseJSON(data: data)
    }
    
    // MARK: - JSON Parser
    
    private static func parseJSON(data: Data) throws -> ParsedConfiguration {
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw AppError.importInvalidFormat("JSON muss ein Array sein")
        }
        
        guard !jsonArray.isEmpty else {
            throw AppError.importInvalidFormat("JSON-Array ist leer")
        }
        
        var toplevelName = "managedFavs"
        var parsedFavorites: [ParsedFavorite] = []
        
        for (index, item) in jsonArray.enumerated() {
            // First item: toplevel_name
            if index == 0, let name = item["toplevel_name"] as? String {
                toplevelName = name
                continue
            }
            
            // Check for folder (has children)
            if let children = item["children"] as? [[String: Any]],
               let name = item["name"] as? String {
                let parsedChildren = try parseJSONChildren(children)
                parsedFavorites.append(ParsedFavorite(
                    name: name,
                    url: nil,
                    children: parsedChildren,
                    order: parsedFavorites.count
                ))
            }
            // Regular favorite (name + url)
            else if let name = item["name"] as? String,
                    let url = item["url"] as? String {
                parsedFavorites.append(ParsedFavorite(
                    name: name,
                    url: url,
                    children: nil,
                    order: parsedFavorites.count
                ))
            }
        }
        
        logger.info("JSON erfolgreich geparst: toplevel=\(toplevelName), items=\(parsedFavorites.count)")
        
        return ParsedConfiguration(toplevelName: toplevelName, favorites: parsedFavorites)
    }
    
    private static func parseJSONChildren(_ children: [[String: Any]]) throws -> [ParsedFavorite] {
        var parsedChildren: [ParsedFavorite] = []
        
        for (index, child) in children.enumerated() {
            guard let name = child["name"] as? String,
                  let url = child["url"] as? String else {
                throw AppError.importInvalidFormat("Child muss 'name' und 'url' enthalten")
            }
            
            parsedChildren.append(ParsedFavorite(
                name: name,
                url: url,
                children: nil,
                order: index
            ))
        }
        
        return parsedChildren
    }
    
    // MARK: - Plist Parser
    
    private static func parsePlist(data: Data) throws -> ParsedConfiguration {
        // Try to parse the plist, but if it's a fragment (no XML header), wrap it
        var plistData = data
        
        // Check if data starts with valid plist header
        if let dataString = String(data: data, encoding: .utf8),
           !dataString.hasPrefix("<?xml") && !dataString.hasPrefix("bplist") {
            // Fragment detected - wrap it in proper plist structure
            logger.info("Plist Fragment detected - wrapping in proper structure")
            
            let wrappedPlist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            \(dataString)
            </dict>
            </plist>
            """
            
            guard let wrappedData = wrappedPlist.data(using: .utf8) else {
                throw AppError.importInvalidFormat("Konnte Plist-Fragment nicht wrappen")
            }
            
            plistData = wrappedData
        }
        
        let plistObject = try PropertyListSerialization.propertyList(from: plistData, format: nil)
        
        // Try to get ManagedFavorites array
        // Option 1: Full plist with dictionary structure { "ManagedFavorites": [...] }
        // Option 2: Fragment plist (direct array) - common in Intune exports
        let managedFavorites: [[String: Any]]
        
        if let plistDict = plistObject as? [String: Any],
           let favorites = plistDict["ManagedFavorites"] as? [[String: Any]] {
            // Full plist format
            managedFavorites = favorites
            logger.info("Plist Format: Full dictionary with ManagedFavorites key")
        } else if let favorites = plistObject as? [[String: Any]] {
            // Fragment format (direct array)
            managedFavorites = favorites
            logger.info("Plist Format: Fragment (direct array)")
        } else {
            throw AppError.importInvalidFormat("Plist muss entweder ein Dictionary mit 'ManagedFavorites' Key oder ein direktes Array sein")
        }
        
        guard !managedFavorites.isEmpty else {
            throw AppError.importInvalidFormat("ManagedFavorites Array ist leer")
        }
        
        var toplevelName = "managedFavs"
        var parsedFavorites: [ParsedFavorite] = []
        
        for (index, item) in managedFavorites.enumerated() {
            // First item: toplevel_name
            if index == 0, let name = item["toplevel_name"] as? String {
                toplevelName = name
                continue
            }
            
            // Check for folder (has children)
            if let children = item["children"] as? [[String: Any]],
               let name = item["name"] as? String {
                let parsedChildren = try parsePlistChildren(children)
                parsedFavorites.append(ParsedFavorite(
                    name: name,
                    url: nil,
                    children: parsedChildren,
                    order: parsedFavorites.count
                ))
            }
            // Regular favorite (name + url)
            else if let name = item["name"] as? String,
                    let url = item["url"] as? String {
                parsedFavorites.append(ParsedFavorite(
                    name: name,
                    url: url,
                    children: nil,
                    order: parsedFavorites.count
                ))
            }
        }
        
        logger.info("Plist erfolgreich geparst: toplevel=\(toplevelName), items=\(parsedFavorites.count)")
        
        return ParsedConfiguration(toplevelName: toplevelName, favorites: parsedFavorites)
    }
    
    private static func parsePlistChildren(_ children: [[String: Any]]) throws -> [ParsedFavorite] {
        var parsedChildren: [ParsedFavorite] = []
        
        for (index, child) in children.enumerated() {
            guard let name = child["name"] as? String,
                  let url = child["url"] as? String else {
                throw AppError.importInvalidFormat("Child muss 'name' und 'url' enthalten")
            }
            
            parsedChildren.append(ParsedFavorite(
                name: name,
                url: url,
                children: nil,
                order: index
            ))
        }
        
        return parsedChildren
    }
}
