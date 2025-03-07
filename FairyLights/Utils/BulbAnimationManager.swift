import SwiftUI
import Combine

@MainActor
class BulbAnimationManager: ObservableObject {
    @Published private(set) var bulbStates: [BulbState] = []
    
    private var glowTimers: [AnyCancellable] = []
    private var colorTimers: [AnyCancellable] = []
    private var isActive = false
    
    func setupBulbs(count: Int) {
        stopAnimations()
        
        bulbStates = (0..<count).map { _ in
            let isUpsideDown = Bool.random()
            
            let rotation = isUpsideDown
            ? CGFloat.random(in: -10...10) + 180
            : CGFloat.random(in: -10...10)
            
            return BulbState(
                color: BulbColor.allCases.randomElement() ?? .red,
                isGlowing: false,
                rotation: rotation,
                isUpsideDown: isUpsideDown
            )
        }
    }
    
    func startAnimations() {
        guard !isActive else { return }
        isActive = true
        
        for index in 0..<bulbStates.count {
            startGlowTimerForBulb(at: index)
            startColorTimerForBulb(at: index)
        }
    }
    
    func stopAnimations() {
        glowTimers.forEach { $0.cancel() }
        colorTimers.forEach { $0.cancel() }
        glowTimers = []
        colorTimers = []
        isActive = false
        bulbStates = []
    }
    
    private func startGlowTimerForBulb(at index: Int) {
        let timer = Timer.publish(
            every: Double.random(in: 0.5...2.0),
            on: .main,
            in: .common
        ).autoconnect()
        
        let cancellable = timer.sink { [weak self] _ in
            guard let self = self else { return }
            
            withAnimation(Animation.easeInOut(duration: 0.6).repeatCount(1, autoreverses: true)) {
                self.bulbStates[index].isGlowing.toggle()
            }
            
            self.glowTimers[index].cancel()
            self.startGlowTimerForBulb(at: index)
        }
        
        if index < glowTimers.count {
            glowTimers[index] = cancellable
        } else {
            glowTimers.append(cancellable)
        }
    }
    
    private func startColorTimerForBulb(at index: Int) {
        let timer = Timer.publish(
            every: Double.random(in: 3.0...5.0),
            on: .main,
            in: .common
        ).autoconnect()
        
        let cancellable = timer.sink { [weak self] _ in
            guard let self = self else { return }
            
            let currentColor = self.bulbStates[index].color
            let newColor = BulbColor.allCases.filter { $0 != currentColor }.randomElement() ?? .red
            
            withAnimation(.easeInOut(duration: 0.8)) {
                self.bulbStates[index].color = newColor
            }
            
            self.colorTimers[index].cancel()
            self.startColorTimerForBulb(at: index)
        }
        
        if index < colorTimers.count {
            colorTimers[index] = cancellable
        } else {
            colorTimers.append(cancellable)
        }
    }
}

struct BulbState {
    var color: BulbColor
    var isGlowing: Bool
    var rotation: CGFloat
    var isUpsideDown: Bool
}
