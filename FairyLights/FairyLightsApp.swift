import SwiftUI
import UserNotifications

@main
struct FairyLightsApp: App {
    @StateObject private var updateManager = UpdateManager()
    @StateObject private var lightsController = LightsController()
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var preferencesWindowIsOpen = false
        
    private let notificationDelegate: NotificationDelegate
    
    init() {
        // Create the update manager first
        let updateManager = UpdateManager()
        _updateManager = StateObject(wrappedValue: updateManager)
        
        // Set up notification delegate
        notificationDelegate = NotificationDelegate(updateManager: updateManager)
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    var body: some Scene {
        MenuBarExtra {
            Group {
                toggleLightsButton
                
                Divider()
                
                updateMenuSection
                
                if let currentVersion = AppVersion.current?.version {
                    Text("Version: \(currentVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button("Preferences...") {
                    openWindow(id: "preferencesWindow")
                }
                .keyboardShortcut(",", modifiers: [.command])
                
                Divider()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        } label: {
            Image(nsImage: menuBarIcon(for: lightsController.isLightsOn))
                .renderingMode(.template)
        }
        
        preferencesWindow
    }
    
    // MARK: - Update Menu Section
    @ViewBuilder
    private var updateMenuSection: some View {
        if case .available(let version, _) = updateManager.status {
            Button("Update Available (\(version))") {
                updateManager.downloadUpdate()
            }
            .foregroundColor(.blue)
            
            Divider()
        }
    }
    
    // MARK: - Toggle Lights
    private var toggleLightsButton: some View {
        Button(action: {
            lightsController.toggleLights()
        }) {
            HStack {
                Image(systemName: lightsController.isLightsOn ? "lightbulb.slash" : "lightbulb.min")
                Text(lightsController.isLightsOn ? "Turn Off" : "Turn On")
            }
        }
    }
    
    // MARK: - Preferences Window
    private var preferencesWindow: some Scene {
        Window("Preferences", id: "preferencesWindow") {
            PreferencesView()
                .environmentObject(updateManager)
                .environmentObject(lightsController)
                .onAppear {
                    preferencesWindowIsOpen = true
                }
                .onDisappear {
                    preferencesWindowIsOpen = false
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .onChange(of: preferencesWindowIsOpen) { _, isOpen in
            NSApp.setActivationPolicy(isOpen ? .regular : .accessory)
            if isOpen {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    // MARK: - Menu Bar Icon
    private func menuBarIcon(for state: Bool) -> NSImage {
        let assetName = state ? "IconOn" : "IconOff"
        let image = NSImage(named: assetName) ?? NSImage()
        let ratio = image.size.height / image.size.width
        image.size.height = 16
        image.size.width = 16 / ratio
        return image
    }
}
