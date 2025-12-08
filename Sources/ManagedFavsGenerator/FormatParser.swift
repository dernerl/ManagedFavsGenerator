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
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw AppError.importInvalidFormat("Plist muss ein Dictionary sein")
        }
        
        guard let managedFavorites = plist["ManagedFavorites"] as? [[String: Any]] else {
            throw AppError.importInvalidFormat("Plist muss 'ManagedFavorites' Array enthalten")
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
