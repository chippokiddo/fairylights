import SwiftUI
import Quartz

@MainActor
class LightsController: ObservableObject {
    @Published var isLightsOn = false
    
    private var windows: [NSWindow] = []
    private var screenChangeTask: Task<Void, Never>?
    private var isObserverAdded = false
    
    init() {
        addScreenObserver()
    }
    
    func toggleLights() {
        isLightsOn.toggle()
        if isLightsOn {
            fadeInLights()
        } else {
            fadeOutLights()
            cancelScreenTask()
        }
    }
    
    private func fadeInLights() {
        clearWindows()
        
        for screen in NSScreen.screens {
            createLightWindow(for: screen)
        }
        
        windows.forEach { $0.alphaValue = 0.0 }
        animateWindows(alpha: 1.0)
    }
    
    private func fadeOutLights() {
        animateWindows(alpha: 0.0) {
            self.clearWindows()
        }
    }
    
    private func createLightWindow(for screen: NSScreen) {
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
            defer: false
        )
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.contentView = NSHostingView(rootView: LightsView(width: screen.frame.width))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.orderFront(nil)
        
        windows.append(window)
    }
    
    private func animateWindows(alpha: CGFloat, completion: (() -> Void)? = nil) {
        guard !windows.isEmpty else { return }
        
        // Remove any existing animations
        for window in self.windows {
            window.contentView?.layer?.removeAllAnimations()
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            for window in self.windows {
                window.animator().alphaValue = alpha
            }
        } completionHandler: {
            completion?()
        }
    }
    
    private func clearWindows() {
        windows.forEach {
            $0.contentView = nil
            $0.close()
        }
        windows.removeAll()
    }
    
    // Handle screen change safely
    private func handleScreenChange() {
        guard isLightsOn else { return }
        
        // Cancel any existing task to avoid multiple instances
        cancelScreenTask()
        
        // Start a new task for screen handling
        screenChangeTask = Task { @MainActor in
            refreshLights()
        }
    }
    
    private func refreshLights() {
        clearWindows()
        fadeInLights()
    }
    
    // Add observer only once
    private func addScreenObserver() {
        guard !isObserverAdded else { return } // Prevent duplicate observers
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenChange()
            }
        }
        
        isObserverAdded = true
    }
    
    // Cancel the running task, if any
    private func cancelScreenTask() {
        screenChangeTask?.cancel()
        screenChangeTask = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSApplication.didChangeScreenParametersNotification, object: nil)
        Task { @MainActor [weak self] in
            self?.cancelScreenTask()
        }
    }
}
