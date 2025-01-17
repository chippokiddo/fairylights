import SwiftUI

struct BulbView: View {
    @State private var currentColor: BulbColor = .red
    @State private var glowVisible: Bool = false
    
    let size: CGFloat = 30
    
    var body: some View {
        ZStack {
            if glowVisible {
                Image("bulb_\(currentColor.rawValue)_glow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }

            Image("bulb_\(currentColor.rawValue)")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
        .onAppear {
            startEffects()
        }
    }
    
    private func startEffects() {
        startRandomTwinkleEffect()
        startRandomColorChangeEffect()
    }
    
    private func startRandomTwinkleEffect() {
        Task.detached {
            while true {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...2_000_000_000))
                await toggleGlow()
            }
        }
    }
    
    private func startRandomColorChangeEffect() {
        Task.detached {
            while true {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 3_000_000_000...5_000_000_000))
                await changeColor()
            }
        }
    }
    
    @MainActor
    private func toggleGlow() {
        withAnimation(Animation.easeInOut(duration: 0.3)) {
            glowVisible.toggle()
        }
    }
    
    @MainActor
    private func changeColor() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentColor = BulbColor.allCases.randomElement() ?? .red
        }
    }
}
