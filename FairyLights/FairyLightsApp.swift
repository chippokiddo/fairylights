import AppKit
import SwiftUI
import Settings
import enum Settings.Settings

@main
struct FairyLightsApp: App {
    @StateObject private var lightsController = LightsController()
    @StateObject private var updateManager = UpdateManager(repoOwner: "chippokiddo", repoName: "fairylights")
    
    private static var preferencesWindow: SettingsWindowController? = nil
    @State private var isCheckingForUpdates = false
    
    var body: some Scene {
        MenuBarExtra {
            Group {
                Button(action: {
                    lightsController.toggleLights()
                }) {
                    HStack {
                        Image(systemName: lightsController.isLightsOn ? "lightbulb.slash" : "lightbulb.min")
                        Text(lightsController.isLightsOn ? "Turn Off" : "Turn On")
                    }
                }
                
                Divider()
                
                if let currentVersion = AppVersion.current?.version {
                    Text("Version: \(currentVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    isCheckingForUpdates = true
                    
                    updateManager.checkForUpdates()
                    
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        isCheckingForUpdates = false
                        
                        let alert = NSAlert()
                        
                        if updateManager.isUpdateAvailable, let version = updateManager.latestVersion {
                            alert.messageText = "Update Available"
                            alert.informativeText = "Version \(version) is available. Would you like to download it now?"
                            alert.addButton(withTitle: "Download")
                            alert.addButton(withTitle: "Later")
                            
                            let response = alert.runModal()
                            if response == .alertFirstButtonReturn {
                                updateManager.downloadUpdate()
                            }
                        } else if let error = updateManager.errorMessage {
                            alert.alertStyle = .warning
                            alert.messageText = "Update Check Failed"
                            alert.informativeText = "Error: \(error)"
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        } else {
                            alert.messageText = "No Update Available"
                            alert.informativeText = "You are already on the latest version."
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }) {
                    HStack {
                        if isCheckingForUpdates {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Text(isCheckingForUpdates ? "Checking..." : "Check for Updates")
                    }
                }
                .disabled(isCheckingForUpdates || updateManager.isChecking)
                
                if updateManager.isUpdateAvailable, let version = updateManager.latestVersion {
                    Button("Download Update \(version)") {
                        updateManager.downloadUpdate()
                    }
                }
                
                Button("Preferences...") {
                    showSettingsWindow()
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
    }
    
    private func menuBarIcon(for state: Bool) -> NSImage {
        let assetName = state ? "IconOn" : "IconOff"
        let image = NSImage(named: assetName) ?? NSImage()
        let ratio = image.size.height / image.size.width
        image.size.height = 16
        image.size.width = 16 / ratio
        return image
    }
    
    private func showSettingsWindow() {
        if Self.preferencesWindow == nil {
            let settingsView = SettingsView(updateManager: updateManager)
            
            let aboutView = AboutView()
            
            Self.preferencesWindow = SettingsWindowController(
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
        Self.preferencesWindow?.show()
    }
    
    // MARK: Preferences Icons
    private func gearToolbarIcon(size: CGFloat = 24, innerSize: CGFloat = 18) -> NSImage {
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
    
    private func infoToolbarIcon(size: CGFloat = 24) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return NSImage(
            systemSymbolName: "info.square.fill",
            accessibilityDescription: nil
        )!.withSymbolConfiguration(config)!
    }
}
