import SwiftUI
import Quartz
import Combine

@MainActor
class LightsController: ObservableObject {
    @Published var isLightsOn = false
    
    private var windowControllers: [NSWindowController] = []
    private var debounceTask: AnyCancellable?
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
            cancelDebounceTask()
        }
    }
    
    private func fadeInLights() {
        if windowControllers.isEmpty {
            createLightWindows()
        }
        
        windowControllers.forEach { controller in
            let window = controller.window
            window?.alphaValue = 0.0
            window?.orderFront(nil)
        }
        
        animateWindows(alpha: 1.0)
    }
    
    private func fadeOutLights() {
        animateWindows(alpha: 0.0) { [weak self] in
            self?.windowControllers.forEach { $0.window?.orderOut(nil) }
            self?.clearWindows()
        }
    }
    
    private func createLightWindows() {
        clearWindows()
        
        for screen in NSScreen.screens {
            let windowController = createLightWindowController(for: screen)
            windowControllers.append(windowController)
        }
    }
    
    private func createLightWindowController(for screen: NSScreen) -> NSWindowController {
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
        
        let controller = NSWindowController(window: window)
        return controller
    }
    
    private func animateWindows(alpha: CGFloat, completion: (() -> Void)? = nil) {
        guard !windowControllers.isEmpty else { return }
        
        for controller in windowControllers {
            controller.window?.contentView?.layer?.removeAllAnimations()
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            for controller in self.windowControllers {
                controller.window?.animator().alphaValue = alpha
            }
        } completionHandler: {
            completion?()
        }
    }
    
    private func clearWindows() {
        windowControllers.forEach {
            $0.window?.contentView = nil
            $0.window?.close()
        }
        windowControllers.removeAll()
    }
    
    // MARK: Screen Change Handling with Debouncing
    private func handleScreenChange() {
        Task { @MainActor in
            guard isLightsOn else { return }
            
            cancelDebounceTask()
            
            debounceTask = Just(())
                .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    Task { @MainActor in
                        self?.refreshLights()
                    }
                }
        }
    }
    
    private func refreshLights() {
        let currentAlphaValues = windowControllers.compactMap { $0.window?.alphaValue }
        let wasVisible = !currentAlphaValues.isEmpty && currentAlphaValues.contains { $0 > 0 }
        
        createLightWindows()
        
        if wasVisible {
            windowControllers.forEach { $0.window?.orderFront(nil) }
            animateWindows(alpha: 1.0)
        }
    }
    
    private func addScreenObserver() {
        guard !isObserverAdded else { return }
        
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
    
    private func cancelDebounceTask() {
        debounceTask?.cancel()
        debounceTask = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        let cancelTask = cancelDebounceTask
        let clearAllWindows = clearWindows
        
        Task { @MainActor in
            cancelTask()
            clearAllWindows()
        }
    }
}
