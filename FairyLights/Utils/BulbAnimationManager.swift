import SwiftUI

// MARK: - Bulb Animation Manager
@MainActor
final class BulbAnimationManager: ObservableObject {
    @Published private(set) var bulbStates: [BulbState] = []
    @Published var lightMode: LightMode = .classic
    
    private var animationTask: Task<Void, Never>?
    private var scheduledTasks = [Task<Void, Never>]()
    private var isActive = false
    private var isInInitialRedState = false
    
    private var lastGlowUpdateTimes = [TimeInterval]()
    private var lastColorUpdateTimes = [TimeInterval]()
    
    private let minGlowInterval: TimeInterval = 1.0
    private let minColorInterval: TimeInterval = 8.0
    private let timerFrequency: TimeInterval = 0.25
    
    deinit {
        isActive = false
        animationTask?.cancel()
        
        for task in scheduledTasks {
            task.cancel()
        }
        
    }
    
    func setupBulbs(count: Int) {
        stopAnimations()
        isInInitialRedState = true
        
        let currentTime = Date().timeIntervalSince1970
        lastGlowUpdateTimes = Array(repeating: currentTime, count: count)
        lastColorUpdateTimes = Array(repeating: currentTime, count: count)
        
        scheduledTasks.removeAll()
        
        bulbStates = (0..<count).map { index in
            let isUpsideDown = Bool.random()
            let rotation = isUpsideDown
            ? CGFloat.random(in: -10...10) + 180
            : CGFloat.random(in: -10...10)
            
            let phaseOffset = Double(index) * 0.4 + Double.random(in: 0...0.5)
            
            return BulbState(
                color: .red,
                isGlowing: true,
                rotation: rotation,
                isUpsideDown: isUpsideDown,
                phaseOffset: phaseOffset
            )
        }
    }
    
    func startAnimations() {
        guard !isActive else { return }
        isActive = true
        
        if isInInitialRedState {
            for task in scheduledTasks {
                task.cancel()
            }
            scheduledTasks.removeAll()
            
            let task = Task { [weak self] in
                try? await Task.sleep(for: .seconds(3.0))
                
                guard let self = self, self.isActive, !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.isInInitialRedState = false
                    
                    for (index, _) in self.bulbStates.enumerated() {
                        let staggerDelay = Double(index) * 0.1
                        self.startRandomizingBulb(at: index, withDelay: staggerDelay)
                    }
                }
            }
            
            scheduledTasks.append(task)
        } else {
            startAnimationLoop()
        }
    }
    
    private func startAnimationLoop() {
        animationTask?.cancel()
        
        animationTask = Task { [weak self] in
            guard let self = self else { return }
            
            for await _ in AsyncTimerSequence(interval: .seconds(self.timerFrequency)) {
                guard self.isActive, !Task.isCancelled else { break }
                
                await MainActor.run {
                    self.updateBulbs()
                }
                
                await Task.yield()
            }
        }
    }
    
    private func updateBulbs() {
        guard !bulbStates.isEmpty else { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        for index in 0..<bulbStates.count {
            guard isActive else { break }
            
            switch lightMode {
            case .classic:
                if currentTime - lastGlowUpdateTimes[index] >= getNextGlowInterval(for: index) {
                    updateGlowState(at: index)
                    lastGlowUpdateTimes[index] = currentTime
                }
                if currentTime - lastColorUpdateTimes[index] >= getNextColorInterval(for: index) {
                    updateColorState(at: index)
                    lastColorUpdateTimes[index] = currentTime
                }
                
            case .pulse:
                let pulsePeriod = 1.5
                let offset = bulbStates[index].phaseOffset
                let phase = sin((2 * .pi / pulsePeriod) * currentTime + offset)
                
                let shouldGlow = phase > 0
                if bulbStates[index].isGlowing != shouldGlow {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        bulbStates[index].isGlowing = shouldGlow
                    }
                }
                
            case .breathe:
                let breathePeriod = 6.0
                let offset = bulbStates[index].phaseOffset
                let phase = sin((2 * .pi / breathePeriod) * currentTime + offset)
                
                let shouldGlow = phase > -0.2
                if bulbStates[index].isGlowing != shouldGlow {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        bulbStates[index].isGlowing = shouldGlow
                    }
                }
            }
        }
    }
    
    private func getNextGlowInterval(for index: Int) -> TimeInterval {
        guard index < bulbStates.count else { return minGlowInterval }
        
        let blinkFrequency = Double((index * 13) % 10) / 10.0
        
        if blinkFrequency < 0.3 {
            return Double.random(in: 3.0...6.0)
        } else if blinkFrequency < 0.7 {
            return Double.random(in: 1.0...3.0)
        } else {
            return Double.random(in: 1.0...2.0)
        }
    }
    
    private func getNextColorInterval(for index: Int) -> TimeInterval {
        return Double.random(in: 8.0...15.0)
    }
    
    private func updateGlowState(at index: Int) {
        guard index < bulbStates.count, isActive else { return }
        
        let isCurrentlyGlowing = bulbStates[index].isGlowing
        let animationDuration = isCurrentlyGlowing ? 0.5 : 0.3
        
        withAnimation(Animation.easeInOut(duration: animationDuration)) {
            bulbStates[index].isGlowing.toggle()
        }
    }
    
    private func updateColorState(at index: Int) {
        guard index < bulbStates.count, isActive else { return }
        
        let currentColor = bulbStates[index].color
        let availableColors = BulbColor.allCases.filter { $0 != currentColor }
        
        let newColor = availableColors.randomElement() ?? availableColors[0]
        
        withAnimation(.easeInOut(duration: 1.2)) {
            bulbStates[index].color = newColor
        }
    }
    
    func stopAnimations() {
        isActive = false
        isInInitialRedState = false
        
        animationTask?.cancel()
        animationTask = nil
        
        for task in scheduledTasks {
            task.cancel()
        }
        scheduledTasks.removeAll()
    }
    
    private func startRandomizingBulb(at index: Int, withDelay delay: Double = 0) {
        guard index < bulbStates.count, isActive else { return }
        
        let task = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            
            guard let self = self, self.isActive,
                  index < self.bulbStates.count,
                  !Task.isCancelled else { return }
            
            await MainActor.run {
                let nonRedColors = BulbColor.allCases.filter { $0 != .red }
                let newColor = nonRedColors[index % nonRedColors.count]
                
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.bulbStates[index].color = newColor
                }
                
                let currentTime = Date().timeIntervalSince1970
                if index < self.lastColorUpdateTimes.count {
                    self.lastColorUpdateTimes[index] = currentTime
                }
                
                if self.animationTask == nil {
                    self.startAnimationLoop()
                }
            }
        }
        
        scheduledTasks.append(task)
    }
}

// MARK: - Bulb State
struct BulbState: Equatable, Sendable {
    var color: BulbColor
    var isGlowing: Bool
    var rotation: CGFloat
    var isUpsideDown: Bool
    var phaseOffset: Double = 0
    
    static func == (lhs: BulbState, rhs: BulbState) -> Bool {
        lhs.color == rhs.color &&
        lhs.isGlowing == rhs.isGlowing &&
        lhs.rotation == rhs.rotation &&
        lhs.isUpsideDown == rhs.isUpsideDown &&
        lhs.phaseOffset == rhs.phaseOffset
    }
}

// MARK: - Async Timer Sequence
struct AsyncTimerSequence: AsyncSequence {
    typealias Element = Void
    
    let interval: Duration
    
    struct AsyncIterator: AsyncIteratorProtocol {
        let interval: Duration
        
        mutating func next() async -> Element? {
            try? await Task.sleep(for: interval)
            return Task.isCancelled ? nil : ()
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(interval: interval)
    }
}

// MARK: - Light Modes
enum LightMode: String, CaseIterable {
    case classic
    case pulse
    case breathe
}
