import Foundation

// Test script to verify favicon URL generation
let testURLs = [
    "https://www.google.com",
    "https://github.com",
    "https://apple.com",
    "http://www.microsoft.com/edge"
]

print("Testing Favicon URL Generation:")
print("================================\n")

for urlString in testURLs {
    if let url = URL(string: urlString),
       let host = url.host {
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        // Google provider
        let googleFavicon = "https://www.google.com/s2/favicons?domain=\(domain)&sz=32"
        
        print("Original URL: \(urlString)")
        print("  Domain: \(domain)")
        print("  Favicon URL: \(googleFavicon)")
        print()
    }
}
