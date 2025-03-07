import SwiftUI

struct BulbView: View {
    let currentColor: BulbColor
    let isGlowing: Bool
    let size: CGFloat
    
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
