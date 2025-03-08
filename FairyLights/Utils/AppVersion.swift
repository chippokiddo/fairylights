import Foundation

struct AppVersion: Comparable {
    let version: String
    let components: [Int]
    
    static var current: AppVersion? {
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return AppVersion(versionString)
    }
    
    init?(_ versionString: String) {
        let cleanString = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        let noPrefix = cleanString.hasPrefix("v") ? String(cleanString.dropFirst()) : cleanString
        
        let parts = noPrefix.split(separator: ".").compactMap { Int($0) }
        guard !parts.isEmpty else { return nil }
        
        self.version = noPrefix
        self.components = parts
    }
    
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        for i in 0..<min(lhs.components.count, rhs.components.count) {
            if lhs.components[i] < rhs.components[i] {
                return true
            } else if lhs.components[i] > rhs.components[i] {
                return false
            }
        }
        return lhs.components.count < rhs.components.count
    }
}
