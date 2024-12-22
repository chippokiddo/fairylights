import AppKit
import SwiftUI
import Settings

@main
struct FairyLightsApp: App {
    @StateObject private var lightsController = LightsController()
    @StateObject private var appState = AppState()
    
    @State private var isCheckingForUpdates = false
    
    var body: some Scene {
        MenuBarExtra {
            VStack {
                Button(lightsController.isLightsOn ? "Turn Off" : "Turn On") {
                    lightsController.toggleLights()
                }
                
                Divider()
                
                Button(action: { checkForAppUpdates() }) {
                    Text(isCheckingForUpdates ? "Checking..." : "Check for Updates")
                }
                .disabled(isCheckingForUpdates)
                
                Button("Preferences...") {
                    showSettingsWindow()
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
    
    // MARK: - Update Check
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
    
    // MARK: - Preferences Window
    private func showSettingsWindow() {
        let settingsView = SettingsView(checkForUpdates: {
            checkForAppUpdates()
        }).environmentObject(appState)
        
        let aboutView = AboutView()
        
        let preferencesWindow = SettingsWindowController(
            panes: [
                Settings.Pane(
                    identifier: Settings.PaneIdentifier("general"),
                    title: "General",
                    toolbarIcon: NSImage(systemSymbolName: "gearshape.circle.fill", accessibilityDescription: nil)!
                ) {
                    settingsView
                },
                Settings.Pane(
                    identifier: Settings.PaneIdentifier("about"),
                    title: "About",
                    toolbarIcon: NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: nil)!
                ) {
                    aboutView
                }
            ]
        )
        
        preferencesWindow.show()
    }
    
    // MARK: - Alert Handling
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
    
    // MARK: - Helper Functions
    private func menuBarIcon(for state: Bool) -> NSImage {
        let assetName = state ? "IconOn" : "IconOff"
        let image = NSImage(named: assetName) ?? NSImage()
        let ratio = image.size.height / image.size.width
        image.size.height = 16
        image.size.width = 16 / ratio
        return image
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
}
