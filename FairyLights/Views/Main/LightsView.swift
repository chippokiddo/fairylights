import SwiftUI

struct LightsView: View {
    let width: CGFloat
    
    @ObservedObject var animationManager: BulbAnimationManager
    
    private let lightSpacing: CGFloat = 60
    private let verticalAmplitude: CGFloat = 10
    private let menuBarHeight = NSStatusBar.system.thickness
    private let bulbHeight: CGFloat = 30
    
    init(width: CGFloat, animationManager: BulbAnimationManager) {
        self.width = width
        self.animationManager = animationManager
    }
    
    var body: some View {
        Group {
            if width > 0 {
                lightsContent
                    .onAppear {
                        setupAnimations()
                    }
                    .onDisappear {
                        stopAnimations()
                    }
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
    }
    
    private var lightsContent: some View {
        ZStack {
            let lightCount = Int((width / lightSpacing).rounded(.down)) + 1
            let startingOffset = (width - CGFloat(lightCount - 1) * lightSpacing) / 2
            
            // Draw the wire
            Path { path in
                path.move(to: CGPoint(x: startingOffset, y: menuBarHeight))
                
                for index in 1..<lightCount {
                    let xOffset = startingOffset + CGFloat(index) * lightSpacing
                    let sineOffset = sin(CGFloat(index) * .pi / 4) * verticalAmplitude
                    let yOffset = menuBarHeight + sineOffset
                    
                    let previousX = startingOffset + CGFloat(index - 1) * lightSpacing
                    let controlX = (xOffset + previousX) / 2
                    let controlY = yOffset + 5
                    
                    path.addQuadCurve(to: CGPoint(x: xOffset, y: yOffset),
                                      control: CGPoint(x: controlX, y: controlY))
                }
            }
            .stroke(Color.black, lineWidth: 3)
            
            // Draw the bulbs
            GeometryReader { geometry in
                ForEach(0..<animationManager.bulbStates.count, id: \.self) { index in
                    let xOffset = startingOffset + CGFloat(index) * lightSpacing
                    let sineOffset = sin(CGFloat(index) * .pi / 4) * verticalAmplitude
                    let wireY = menuBarHeight + sineOffset
                    
                    let bulbState = animationManager.bulbStates[index]
                    
                    let yAdjustment = bulbState.isUpsideDown ? 0 : -bulbHeight
                    let positionY = wireY + (bulbHeight / 2) + yAdjustment
                    
                    BulbView(
                        currentColor: bulbState.color,
                        isGlowing: bulbState.isGlowing,
                        size: bulbHeight
                    )
                    .frame(width: bulbHeight, height: bulbHeight)
                    .rotationEffect(.degrees(bulbState.rotation))
                    .position(x: xOffset, y: positionY)
                }
            }
        }
        .frame(width: width, height: menuBarHeight + 2*bulbHeight + verticalAmplitude)
        .background(Color.clear)
    }
    
    private func setupAnimations() {
        guard width > 0 else { return }
        
        let lightCount = Int((width / lightSpacing).rounded(.down)) + 1
        
        Task { @MainActor in
            animationManager.setupBulbs(count: lightCount)
            animationManager.startAnimations()
        }
    }
    
    private func stopAnimations() {
        Task { @MainActor in
            animationManager.stopAnimations()
            animationManager.setupBulbs(count: 0)
        }
    }
}
