import Foundation
import SwiftUI
import AppKit

@MainActor
class UpdateManager: ObservableObject {
    @Published var isChecking = false
    @Published var isUpdateAvailable = false
    @Published var latestVersion: String?
    @Published var downloadURL: URL?
    @Published var errorMessage: String?
    @Published var hasCheckedForUpdates = false
    
    private let repoOwner: String
    private let repoName: String
    
    private var updateCheckTask: Task<Void, Never>?
    
    private enum Keys {
        static let automaticUpdates = "automaticUpdateChecks"
        static let updateFrequency = "updateCheckFrequency"
        static let lastUpdateCheck = "lastUpdateCheck"
    }
    
    init(repoOwner: String, repoName: String) {
        self.repoOwner = repoOwner
        self.repoName = repoName
        
        setupAutomaticUpdates()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    deinit {
        updateCheckTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
        
    func checkForUpdates() {
        guard !isChecking else { return }
        
        isChecking = true
        errorMessage = nil
        
        updateCheckTask?.cancel()
        updateCheckTask = Task {
            do {
                let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
                guard let url = URL(string: urlString) else {
                    await handleError("Invalid URL")
                    return
                }
                
                var request = URLRequest(url: url)
                request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await handleError("Invalid response")
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    await handleError("HTTP error: \(httpResponse.statusCode)")
                    return
                }
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    await handleError("Invalid JSON response")
                    return
                }
                
                guard let tagName = json["tag_name"] as? String else {
                    await handleError("Missing tag name")
                    return
                }
                
                guard let assets = json["assets"] as? [[String: Any]], !assets.isEmpty else {
                    await handleError("No assets available")
                    return
                }
                
                var downloadAsset: URL? = nil
                for asset in assets {
                    if let name = asset["name"] as? String,
                       (name.hasSuffix(".dmg") || name.hasSuffix(".zip") || name.hasSuffix(".pkg")),
                       let downloadURLString = asset["browser_download_url"] as? String,
                       let assetURL = URL(string: downloadURLString) {
                        downloadAsset = assetURL
                        break
                    }
                }
                
                guard let downloadAsset = downloadAsset else {
                    await handleError("No suitable download found")
                    return
                }
                
                guard let currentVersion = AppVersion.current,
                      let remoteVersion = AppVersion(tagName) else {
                    await handleError("Invalid version format")
                    return
                }
                
                await MainActor.run {
                    UserDefaults.standard.set(Date(), forKey: Keys.lastUpdateCheck)
                    
                    if remoteVersion > currentVersion {
                        self.latestVersion = remoteVersion.version
                        self.downloadURL = downloadAsset
                        self.isUpdateAvailable = true
                    } else {
                        self.isUpdateAvailable = false
                    }
                    
                    self.isChecking = false
                    self.errorMessage = nil
                    self.hasCheckedForUpdates = true
                }
                
                if remoteVersion > currentVersion {
                    await showUpdateAlert(version: remoteVersion.version)
                }
                
            } catch {
                await handleError(error.localizedDescription)
            }
        }
    }
    
    func downloadUpdate() {
        guard let url = downloadURL else { return }
        NSWorkspace.shared.open(url)
    }
        
    private func handleError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isChecking = false
        }
    }
    
    private func showUpdateAlert(version: String) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "Update Available"
            alert.informativeText = "Version \(version) is available. Would you like to download it now?"
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Later")
            
            if alert.runModal() == .alertFirstButtonReturn {
                self.downloadUpdate()
            }
        }
    }
    
    // MARK: Automatic Updates
    @objc private func userDefaultsDidChange() {
        Task { @MainActor in
            setupAutomaticUpdates()
        }
    }
    
    private func setupAutomaticUpdates() {
        updateCheckTask?.cancel()
        
        let isEnabled = UserDefaults.standard.bool(forKey: Keys.automaticUpdates)
        guard isEnabled else { return }
        
        let frequency = UserDefaults.standard.double(forKey: Keys.updateFrequency)
        let interval = frequency > 0 ? frequency : 604800.0 // 1 week in seconds
        
        updateCheckTask = Task { [weak self] in
            guard let self = self else { return }
            
            let lastCheck = UserDefaults.standard.object(forKey: Keys.lastUpdateCheck) as? Date ?? .distantPast
            let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
            
            if timeSinceLastCheck > interval {
                try? await Task.sleep(for: .seconds(2))
                if !Task.isCancelled {
                    self.checkForUpdates()
                }
            }
            
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                if !Task.isCancelled {
                    self.checkForUpdates()
                }
            }
        }
    }
}
