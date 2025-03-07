import SwiftUI
import Quartz
import Combine

@MainActor
class LightsController: ObservableObject {
    @Published var isLightsOn = false
    
    private var windowControllers: [NSWindowController]? = []
    private var debounceTask: AnyCancellable?
    private var observers: Set<AnyCancellable>? = Set()
    private var isAnimating = false
    
    private var memoryMonitor: DispatchSourceMemoryPressure?
    
    private var lastScreenUpdateTime: TimeInterval = 0
    private let screenUpdateThrottle: TimeInterval = 1.0
    
    init() {
        setupMemoryPressureMonitor()
        addScreenObserver()
    }
    
    private func setupMemoryPressureMonitor() {
        memoryMonitor = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])
        memoryMonitor?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.handleMemoryPressure()
            }
        }
        memoryMonitor?.resume()
    }
    
    private func handleMemoryPressure() {
        if !isLightsOn {
            aggressiveMemoryCleanup()
        }
    }
    
    func toggleLights() {
        guard !isAnimating else { return }
        
        isLightsOn.toggle()
        
        if isLightsOn {
            fadeInLights()
        } else {
            fadeOutLights()
            cancelDebounceTask()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self, !self.isLightsOn else { return }
                self.aggressiveMemoryCleanup()
            }
        }
    }
    
    private func fadeInLights() {
        isAnimating = true
        
        if windowControllers?.isEmpty == false {
            clearWindows()
        }
        
        if windowControllers == nil {
            windowControllers = []
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isLightsOn else {
                self?.isAnimating = false
                return
            }
            
            self.createLightWindows()
            
            self.windowControllers?.forEach { controller in
                controller.window?.alphaValue = 0.0
                controller.window?.orderFront(nil)
            }
            
            self.animateWindows(alpha: 1.0) {
                self.isAnimating = false
            }
        }
    }
    
    private func fadeOutLights() {
        guard windowControllers?.isEmpty == false else { return }
        
        isAnimating = true
        
        animateWindows(alpha: 0.0) { [weak self] in
            guard let self = self else { return }
            
            self.windowControllers?.forEach { $0.window?.orderOut(nil) }
            self.clearWindows()
            self.isAnimating = false
        }
    }
    
    private func createLightWindows() {
        clearWindows()
        
        if let mainScreen = NSScreen.main {
            if let windowController = createLightWindowController(for: mainScreen) {
                windowControllers?.append(windowController)
            }
        }
    }
    
    private func createLightWindowController(for screen: NSScreen) -> NSWindowController? {
        let menuBarHeight = NSStatusBar.system.thickness
        let lightsHeight: CGFloat = 50
        
        let windowFrame = NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y + screen.frame.height - menuBarHeight - lightsHeight,
            width: screen.frame.width,
            height: lightsHeight
        )
        
        let window = NSWindow(
            contentRect: windowFrame,
            styleMask: [],
            backing: .buffered,
            defer: true
        )
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.displaysWhenScreenProfileChanges = false
        
        let lightsView = LightsView(width: screen.frame.width)
        let hostingView = NSHostingView(rootView: lightsView)
        
        hostingView.layer?.drawsAsynchronously = true
        hostingView.layer?.shouldRasterize = false
        
        window.contentView = hostingView
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        
        return NSWindowController(window: window)
    }
    
    private func animateWindows(alpha: CGFloat, completion: (() -> Void)? = nil) {
        guard windowControllers?.isEmpty == false else {
            completion?()
            return
        }
        
        windowControllers?.forEach { controller in
            controller.window?.contentView?.layer?.removeAllAnimations()
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.windowControllers?.forEach { controller in
                controller.window?.animator().alphaValue = alpha
            }
        } completionHandler: {
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    private func clearWindows() {
        windowControllers?.forEach { controller in
            if let window = controller.window {
                window.contentView?.layer?.removeAllAnimations()
                
                if let hostingView = window.contentView as? NSHostingView<LightsView> {
                    hostingView.rootView = LightsView(width: 0)
                }
                
                window.delegate = nil
                window.contentView = nil
                window.close()
            }
        }
        
        windowControllers?.removeAll(keepingCapacity: false)
    }
    
    private func aggressiveMemoryCleanup() {
        clearWindows()
        
        windowControllers = nil
        
        for _ in 1...3 {
            autoreleasepool {
                // Empty autorelease pool to help flush retained objects
            }
        }
        
        #if DEBUG
        NotificationCenter.default.post(name: NSNotification.Name("_UIApplicationMemoryWarningNotification"), object: nil)
        #endif
    }
    
    private func handleScreenChange() {
        Task { @MainActor in
            guard isLightsOn else { return }
            
            let currentTime = Date().timeIntervalSince1970
            guard (currentTime - lastScreenUpdateTime) >= screenUpdateThrottle else { return }
            lastScreenUpdateTime = currentTime
            
            cancelDebounceTask()
            
            if observers == nil {
                observers = Set()
            }
            
            debounceTask = Just(())
                .delay(for: .seconds(1.0), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    Task { @MainActor in
                        self?.refreshLights()
                    }
                }
                
            if let task = debounceTask, observers != nil {
                observers?.insert(task)
            }
        }
    }
    
    private func refreshLights() {
        guard let controllers = windowControllers else { return }
        
        let currentAlphaValues = controllers.compactMap { $0.window?.alphaValue }
        let wasVisible = !currentAlphaValues.isEmpty && currentAlphaValues.contains { $0 > 0 }
        
        guard wasVisible else { return }
        
        clearWindows()
        createLightWindows()
        windowControllers?.forEach { $0.window?.orderFront(nil) }
        
        windowControllers?.forEach { $0.window?.alphaValue = 1.0 }
    }
    
    private func addScreenObserver() {
        if observers == nil {
            observers = Set()
        }
        
        let publisher = NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification
        )
        
        let observer = publisher
            .throttle(for: .seconds(1.0), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleScreenChange()
                }
            }
        
        observers?.insert(observer)
    }
    
    @MainActor
    private func cancelDebounceTask() {
        debounceTask?.cancel()
        debounceTask = nil
    }
    
    func prepareForDeinit() {
        memoryMonitor?.cancel()
        memoryMonitor = nil
        
        observers?.forEach { $0.cancel() }
        observers?.removeAll(keepingCapacity: false)
        observers = nil
        
        cancelDebounceTask()
        clearWindows()
        windowControllers = nil
        
        aggressiveMemoryCleanup()
    }
    
    deinit {
        // Cannot access MainActor-isolated properties or methods in deinit
        // All cleanup must be done by calling prepareForDeinit()
        // manually before the object is deallocated
    }
}
