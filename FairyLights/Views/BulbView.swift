import SwiftUI

struct BulbView: View, Equatable {
    let currentColor: BulbColor
    let isGlowing: Bool
    let size: CGFloat
    
    private static var imageCache: [String: Image] = [:]
    
    static func clearImageCache() {
        imageCache.removeAll()
    }
    
    private func cachedImage(named imageName: String) -> Image {
        if let cachedImage = BulbView.imageCache[imageName] {
            return cachedImage
        }
        
        let image = Image(imageName)
        BulbView.imageCache[imageName] = image
        return image
    }
    
    static nonisolated func == (lhs: Self, rhs: Self) -> Bool {
        lhs.currentColor == rhs.currentColor &&
        lhs.isGlowing == rhs.isGlowing &&
        lhs.size == rhs.size
    }
    
    var body: some View {
        ZStack {
            Image("bulb_\(currentColor.rawValue)")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
            
            Image("bulb_\(currentColor.rawValue)_glow")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(isGlowing ? 1.0 : 0.0)
        }
    }
}

enum BulbColor: String, CaseIterable {
    case red, green, yellow, blue
}
