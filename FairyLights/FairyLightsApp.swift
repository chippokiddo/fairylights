import AppKit
import SwiftUI
import Settings
import enum Settings.Settings
import Sparkle

@main
struct FairyLightsApp: App {
    @StateObject private var lightsController = LightsController()
    
    private let updaterController: SPUStandardUpdaterController
    private let gentleUpdaterDelegate = GentleUpdaterDelegate()
    
    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "SUEnableAutomaticChecks") == nil {
            defaults.set(false, forKey: "SUEnableAutomaticChecks")
        }
        
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: gentleUpdaterDelegate
        )
        
        gentleUpdaterDelegate.updaterController = updaterController
    }
    
    private static var preferencesWindow: SettingsWindowController? = nil
    
    var body: some Scene {
        MenuBarExtra {
            VStack {
                Button(lightsController.isLightsOn ? "Turn Off" : "Turn On") {
                    lightsController.toggleLights()
                }
                
                Divider()
                
                Text("Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { checkForUpdates() }) {
                    Text("Check for Updates")
                }
                
                Button("Preferences...") {
                    FairyLightsApp.showSettingsWindow(
                        updater: updaterController.updater,
                        checkForUpdates: checkForUpdates
                    )
                }
                .keyboardShortcut(",", modifiers: [.command])
                
                Divider()
                
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("Q", modifiers: [.command])
            }
        } label: {
            Image(nsImage: menuBarIcon(for: lightsController.isLightsOn))
                .renderingMode(.template)
        }
    }
    
    private func menuBarIcon(for state: Bool) -> NSImage {
        let assetName = state ? "IconOn" : "IconOff"
        let image = NSImage(named: assetName) ?? NSImage()
        let ratio = image.size.height / image.size.width
        image.size.height = 16
        image.size.width = 16 / ratio
        return image
    }
    
    // MARK: Preferences Window
    static func showSettingsWindow(updater: SPUUpdater, checkForUpdates: @escaping () -> Void) {
        if preferencesWindow == nil {
            let settingsView = SettingsView(
                updater: updater,
                checkForUpdates: checkForUpdates
            )
            
            let aboutView = AboutView()
            
            preferencesWindow = SettingsWindowController(
                panes: [
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("general"),
                        title: "General",
                        toolbarIcon: { gearToolbarIcon() }()
                    ) {
                        settingsView
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("about"),
                        title: "About",
                        toolbarIcon: { infoToolbarIcon() }()
                    ) {
                        aboutView
                    }
                ]
            )
        }
        preferencesWindow?.show()
    }
    
    // MARK: Update Check
    private func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    // MARK: Preferences Icons
    private static func gearToolbarIcon(size: CGFloat = 24, innerSize: CGFloat = 18) -> NSImage {
        let originalImage = NSImage(named: "squareGear") ?? NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!
        let paddedSize = NSSize(width: size, height: size)
        let innerSize = NSSize(width: innerSize, height: innerSize)
        
        let paddedImage = NSImage(size: paddedSize)
        paddedImage.lockFocus()
        
        let xOffset = (paddedSize.width - innerSize.width) / 2
        let yOffset = (paddedSize.height - innerSize.height) / 2
        originalImage.draw(
            in: NSRect(x: xOffset, y: yOffset, width: innerSize.width, height: innerSize.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        
        paddedImage.unlockFocus()
        paddedImage.isTemplate = true
        return paddedImage
    }
    
    private static func infoToolbarIcon(size: CGFloat = 24) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return NSImage(
            systemSymbolName: "info.square.fill",
            accessibilityDescription: nil
        )!.withSymbolConfiguration(config)!
    }
}
