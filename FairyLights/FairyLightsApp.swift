import AppKit
import SwiftUI
import Settings
import enum Settings.Settings

@main
struct FairyLightsApp: App {
    @StateObject private var lightsController = LightsController()
    @StateObject private var appState = AppState()
    
    @State private var isCheckingForUpdates = false
    
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
                
                Button(action: { checkForAppUpdates() }) {
                    Text(appState.isCheckingForUpdates ? "Checking..." : "Check for Updates")
                }
                .disabled(appState.isCheckingForUpdates)
                
                Button("Preferences...") {
                    FairyLightsApp.showSettingsWindow(appState: appState, checkForUpdates: checkForAppUpdates)
                }
                .keyboardShortcut(",", modifiers: [.command])
                
                Divider()
                
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("Q", modifiers: [.command])
            }
            .onAppear {
                appState.scheduleNextUpdateCheck(checkForUpdates: checkForAppUpdates)
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
    static func showSettingsWindow(appState: AppState, checkForUpdates: @escaping () -> Void) {
        if preferencesWindow == nil {
            let settingsView = SettingsView(checkForUpdates: {
                checkForUpdates()
            }).environmentObject(appState)
            
            let aboutView = AboutView().environmentObject(appState)
            
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
    
    // MARK: Alert Handling
    private func showAlert(
        title: String, message: String, style: NSAlert.Style, buttons: [String] = ["OK"],
        completion: ((NSApplication.ModalResponse) -> Void)? = nil
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        buttons.forEach { alert.addButton(withTitle: $0) }
        let response = alert.runModal()
        completion?(response)
    }
    
    // MARK: Update Check
    private func checkForAppUpdates() {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        Task { @MainActor in
            defer { isCheckingForUpdates = false }
            do {
                let (latestVersion, downloadURL) = try await fetchLatestRelease()
                handleUpdateCheckResult(latestVersion: latestVersion, downloadURL: downloadURL)
            } catch {
                showAlert(
                    title: "Update Check Failed", message: error.localizedDescription, style: .warning)
            }
        }
    }
    
    private func handleUpdateCheckResult(latestVersion: String, downloadURL: URL) {
        let currentVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        
        if isNewerVersion(latestVersion, than: currentVersion) {
            showAlert(
                title: "New Update Available",
                message: "Fairy Lights \(latestVersion) is available. Would you like to download it?",
                style: .informational,
                buttons: ["Download", "Later"]
            ) { response in
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(downloadURL)
                }
            }
        } else {
            showAlert(
                title: "No Updates Available",
                message: "You are already on the latest version.",
                style: .informational)
        }
    }
    
    private func isNewerVersion(_ newVersion: String, than currentVersion: String) -> Bool {
        let parse = { (version: String) in version.split(separator: ".").compactMap { Int($0) } }
        let newComponents = parse(newVersion)
        let currentComponents = parse(currentVersion)
        
        for (new, current) in zip(newComponents, currentComponents) {
            if new != current { return new > current }
        }
        return newComponents.count > currentComponents.count
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
