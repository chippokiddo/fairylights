import SwiftUI
import Combine

@MainActor
class BulbAnimationManager: ObservableObject {
    @Published private(set) var bulbStates: [BulbState] = []
    
    private var masterTimer: AnyCancellable?
    private var scheduledTasks: [DispatchWorkItem]? = []
    private var isActive = false
    private var isInInitialRedState = false
    
    private var lastGlowUpdateTimes: [TimeInterval]? = []
    private var lastColorUpdateTimes: [TimeInterval]? = []
    
    private let minGlowInterval: TimeInterval = 1.0
    private let minColorInterval: TimeInterval = 8.0
    private let timerFrequency: TimeInterval = 0.25
    
    func setupBulbs(count: Int) {
        stopAnimations()
        isInInitialRedState = true
        
        let currentTime = Date().timeIntervalSince1970
        lastGlowUpdateTimes = Array(repeating: currentTime, count: count)
        lastColorUpdateTimes = Array(repeating: currentTime, count: count)
        
        if scheduledTasks == nil {
            scheduledTasks = []
        }
        
        bulbStates = (0..<count).map { _ in
            let isUpsideDown = Bool.random()
            let rotation = isUpsideDown
                ? CGFloat.random(in: -10...10) + 180
                : CGFloat.random(in: -10...10)
            
            return BulbState(
                color: .red,
                isGlowing: true,
                rotation: rotation,
                isUpsideDown: isUpsideDown
            )
        }
    }
    
    func startAnimations() {
        guard !isActive else { return }
        isActive = true
        
        if isInInitialRedState {
            scheduledTasks?.forEach { $0.cancel() }
            scheduledTasks?.removeAll(keepingCapacity: false)
            
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self, self.isActive else { return }
                self.isInInitialRedState = false
                
                for (index, _) in self.bulbStates.enumerated() {
                    let staggerDelay = Double(index) * 0.1
                    self.startRandomizingBulb(at: index, withDelay: staggerDelay)
                }
            }
            
            scheduledTasks?.append(workItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
        } else {
            startMasterTimer()
        }
    }
    
    private func startMasterTimer() {
        masterTimer?.cancel()
        
        masterTimer = Timer.publish(
            every: timerFrequency,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            guard let self = self, self.isActive else { return }
            
            let currentTime = Date().timeIntervalSince1970
            
            guard let glowTimes = self.lastGlowUpdateTimes,
                  let colorTimes = self.lastColorUpdateTimes,
                  !self.bulbStates.isEmpty else { return }
            
            for index in 0..<self.bulbStates.count {
                guard index < glowTimes.count, index < colorTimes.count else { continue }
                
                if currentTime - glowTimes[index] >= self.getNextGlowInterval(for: index) {
                    self.updateGlowState(at: index)
                    self.lastGlowUpdateTimes?[index] = currentTime
                }
                
                if currentTime - colorTimes[index] >= self.getNextColorInterval(for: index) {
                    self.updateColorState(at: index)
                    self.lastColorUpdateTimes?[index] = currentTime
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
        
        let newColorIndex = (index + Int(Date().timeIntervalSince1970)) % availableColors.count
        let newColor = availableColors[newColorIndex]
        
        withAnimation(.easeInOut(duration: 1.2)) {
            bulbStates[index].color = newColor
        }
    }
    
    func stopAnimations() {
        masterTimer?.cancel()
        masterTimer = nil
        
        scheduledTasks?.forEach { $0.cancel() }
        scheduledTasks?.removeAll(keepingCapacity: false)
        
        isActive = false
        isInInitialRedState = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.isActive else { return }
            self.aggressiveMemoryCleanup()
        }
    }
    
    private func aggressiveMemoryCleanup() {
        bulbStates.removeAll(keepingCapacity: false)
        
        lastGlowUpdateTimes = nil
        lastColorUpdateTimes = nil
        scheduledTasks = nil
        
        for _ in 1...3 {
            autoreleasepool {
                // Empty autoreleasepool to flush retained objects
            }
        }
    }
    
    private func startRandomizingBulb(at index: Int, withDelay delay: Double = 0) {
        guard index < bulbStates.count, isActive, scheduledTasks != nil else { return }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.isActive, index < self.bulbStates.count else { return }
            
            let newColor = BulbColor.allCases.filter { $0 != .red }[index % (BulbColor.allCases.count - 1)]
            
            withAnimation(.easeInOut(duration: 0.8)) {
                self.bulbStates[index].color = newColor
            }
            
            let currentTime = Date().timeIntervalSince1970
            if let colorTimes = self.lastColorUpdateTimes, index < colorTimes.count {
                self.lastColorUpdateTimes?[index] = currentTime
            }
            
            if self.masterTimer == nil {
                self.startMasterTimer()
            }
        }
        
        scheduledTasks?.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    func prepareForDeinit() {
        stopAnimations()
        
        masterTimer?.cancel()
        masterTimer = nil
        
        scheduledTasks?.forEach { $0.cancel() }
        scheduledTasks = nil
        
        bulbStates.removeAll(keepingCapacity: false)
        lastGlowUpdateTimes = nil
        lastColorUpdateTimes = nil
        
        for _ in 1...3 {
            autoreleasepool {
                // Empty autorelease pool
            }
        }
    }
    
    deinit {
        // Cannot access MainActor-isolated properties or methods in deinit
        // All cleanup must be done by calling prepareForDeinit()
        // manually before the object is deallocated
    }
}

struct BulbState: Equatable {
    var color: BulbColor
    var isGlowing: Bool
    var rotation: CGFloat
    var isUpsideDown: Bool
    
    static func == (lhs: BulbState, rhs: BulbState) -> Bool {
        lhs.color == rhs.color &&
        lhs.isGlowing == rhs.isGlowing &&
        lhs.rotation == rhs.rotation &&
        lhs.isUpsideDown == rhs.isUpsideDown
    }
}
