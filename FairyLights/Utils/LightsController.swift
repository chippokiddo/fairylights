import SwiftUI
import Combine

@MainActor
final class LightsController: ObservableObject {
    @Published var isLightsOn = false
    @Published private var observedLightMode: String
    @Published private var observedSolidColor: String = UserDefaults.standard.string(forKey: "solidColorChoice") ?? "default"
    
    private var lastLightMode: String = UserDefaults.standard.string(forKey: "lightMode") ?? LightMode.classic.rawValue
    private var windowControllers = [NSWindowController]()
    private var animationManagers = [BulbAnimationManager]()
    private var cancellables = Set<AnyCancellable>()
    private var isAnimating = false
    
    init() {
        self.observedLightMode = UserDefaults.standard.string(forKey: "lightMode") ?? LightMode.classic.rawValue

        $observedLightMode
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self = self else { return }

                if newValue != self.lastLightMode {
                    self.lastLightMode = newValue

                    if self.isLightsOn {
                        self.toggleLights()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                            guard let self = self else { return }
                            self.toggleLights()
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $observedSolidColor
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self = self else { return }

                if self.isLightsOn {
                    self.toggleLights()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.toggleLights()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        print("LightsController deinit called")
    }
    
    func syncLightMode() {
        let newValue = UserDefaults.standard.string(forKey: "lightMode") ?? LightMode.classic.rawValue
        observedLightMode = newValue
    }
    
    func syncSolidColor() {
        let newValue = UserDefaults.standard.string(forKey: "solidColorChoice") ?? "default"
        observedSolidColor = newValue
    }
    
    func toggleLights() {
        guard !isAnimating else { return }
        
        isLightsOn.toggle()
        
        if isLightsOn {
            displayLights()
        } else {
            hideLights()
        }
    }
    
    private func displayLights() {
        isAnimating = true
        
        clearWindows()
        
        Task { [weak self] in
            guard let self = self, self.isLightsOn else {
                self?.isAnimating = false
                return
            }
            
            await MainActor.run {
                self.createLightWindows()
                
                self.windowControllers.forEach { controller in
                    controller.window?.alphaValue = 0.0
                    controller.window?.orderFront(nil)
                }
                
                self.animateWindowsIn {
                    self.isAnimating = false
                }
            }
        }
    }
    
    private func hideLights() {
        guard !windowControllers.isEmpty else { return }
        
        isAnimating = true
        
        let localControllers = windowControllers
        
        Task { [weak self] in
            guard let self = self else {
                await MainActor.run {
                    for controller in localControllers {
                        controller.window?.orderOut(nil)
                    }
                }
                return
            }
            
            await MainActor.run {
                self.animateWindowsOut {
                    self.clearWindows()
                    BulbView.clearImageCache()
                    self.isAnimating = false
                }
            }
        }
    }
    
    private func createLightWindows() {
        guard let mainScreen = NSScreen.main else { return }
        if let windowController = createLightWindowController(for: mainScreen) {
            windowControllers.append(windowController)
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
        
        let animationManager = BulbAnimationManager()
        animationManager.lightMode = LightMode(rawValue: UserDefaults.standard.string(forKey: "lightMode") ?? "classic") ?? .classic
        self.animationManagers.append(animationManager)
        
        let lightsView = LightsView(width: screen.frame.width, animationManager: animationManager)
        let hostingView = NSHostingView(rootView: lightsView)
        
        hostingView.layer?.drawsAsynchronously = true
        hostingView.layer?.shouldRasterize = false
        
        window.contentView = hostingView
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        
        return NSWindowController(window: window)
    }
    
    private func animateWindowsIn(completion: @escaping () -> Void) {
        guard !windowControllers.isEmpty else {
            completion()
            return
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.windowControllers.forEach { controller in
                controller.window?.animator().alphaValue = 1.0
            }
        } completionHandler: { [weak self] in
            guard self != nil else { return }
            completion()
        }
    }
    
    private func animateWindowsOut(completion: @escaping () -> Void) {
        guard !windowControllers.isEmpty else {
            completion()
            return
        }
        
        windowControllers.forEach { controller in
            controller.window?.contentView?.layer?.removeAllAnimations()
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.windowControllers.forEach { controller in
                controller.window?.animator().alphaValue = 0.0
            }
        } completionHandler: { [weak self] in
            guard let self = self else { return }
            
            self.windowControllers.forEach { $0.window?.orderOut(nil) }
            completion()
        }
    }
    
    private func clearWindows() {
        let controllers = windowControllers
        windowControllers.removeAll()
        
        for manager in animationManagers {
            manager.stopAnimations()
        }
        animationManagers.removeAll()
        
        for controller in controllers {
            if let window = controller.window {
                window.contentView?.layer?.removeAllAnimations()
                
                window.contentView = nil
                window.delegate = nil
                window.close()
            }
        }
    }
}
