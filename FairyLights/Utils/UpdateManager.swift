import SwiftUI
import UserNotifications

// MARK: - Update Status
enum UpdateStatus: Equatable {
    case idle
    case checking
    case available(version: String, url: URL)
    case upToDate
    case error(message: String)
}

// MARK: - GitHub API Models
private struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

private struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

// MARK: - Update Manager
@MainActor
class UpdateManager: ObservableObject {
    @Published var status: UpdateStatus = .idle
    
    private let repoOwner = "chippokiddo"
    private let repoName = "fairylights"
    private var updateTimer: Timer?
    
    // Access to user preferences
    @AppStorage("automaticUpdateChecks") private var automaticUpdateChecks = false {
        didSet {
            setupAutomaticChecking()
        }
    }
    
    @AppStorage("updateCheckFrequency") private var updateCheckFrequency: Double = 604800.0 {
        didSet {
            setupAutomaticChecking()
        }
    }
    
    @AppStorage("lastUpdateCheck") private var lastUpdateCheck: Double = 0
    
    init() {
        // Request notification permissions on first launch
        Task {
            await requestNotificationPermissions()
        }
        
        // Set up automatic checking based on current preferences
        setupAutomaticChecking()
        
        // Check for updates on launch if enabled and enough time has passed
        if automaticUpdateChecks && shouldCheckForUpdates() {
            Task {
                await performInitialCheck()
            }
        }
    }
    
    // MARK: - Public Methods
    func checkForUpdates(completion: ((UpdateStatus) -> Void)? = nil) {
        status = .checking
        Task {
            await fetchLatestRelease()
            
            // Show notification if update is available and this is an automatic check
            if case .available(let version, _) = status, completion == nil {
                await showUpdateNotification(version: version)
            }
            
            // Update last check time
            lastUpdateCheck = Date().timeIntervalSince1970
            
            completion?(status)
        }
    }
    
    func downloadUpdate() {
        if case let .available(_, url) = status {
            NSWorkspace.shared.open(url)
        }
    }
    
    func setupAutomaticChecking() {
        // Always invalidate existing timer
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Only set up new timer if automatic updates are enabled
        guard automaticUpdateChecks else { return }
        
        print("Setting up automatic update checking every \(updateCheckFrequency) seconds")
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateCheckFrequency, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForUpdates()
            }
        }
    }
    
    // MARK: - Private Methods
    private func performInitialCheck() async {
        // Small delay to avoid checking immediately on launch
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        checkForUpdates()
    }
    
    private func shouldCheckForUpdates() -> Bool {
        let now = Date().timeIntervalSince1970
        return (now - lastUpdateCheck) >= updateCheckFrequency
    }
    
    private func requestNotificationPermissions() async {
        await Task.detached {
            let center = UNUserNotificationCenter.current()
            
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    print("Notification permissions granted")
                } else {
                    print("Notification permissions denied")
                }
            } catch {
                print("Notification permission error: \(error)")
            }
            
            // Set up notification categories
            let downloadAction = UNNotificationAction(
                identifier: "DOWNLOAD_UPDATE",
                title: "Download",
                options: [.foreground]
            )
            
            let laterAction = UNNotificationAction(
                identifier: "LATER",
                title: "Later",
                options: []
            )
            
            let category = UNNotificationCategory(
                identifier: "UPDATE_AVAILABLE",
                actions: [downloadAction, laterAction],
                intentIdentifiers: [],
                options: []
            )
            
            center.setNotificationCategories([category])
        }.value
    }
    
    private func showUpdateNotification(version: String) async {
        await Task.detached {
            let center = UNUserNotificationCenter.current()
            
            // Check if notifications are authorized
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else {
                print("Notifications not authorized, skipping notification")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Fairy Lights Update Available"
            content.body = "Version \(version) is now available for download."
            content.sound = .default
            content.categoryIdentifier = "UPDATE_AVAILABLE"
            
            let request = UNNotificationRequest(
                identifier: "update-available-\(version)",
                content: content,
                trigger: nil // Show immediately
            )
            
            do {
                try await center.add(request)
                print("Update notification shown for version \(version)")
            } catch {
                print("Failed to show notification: \(error)")
            }
        }.value
    }
    
    private func fetchLatestRelease() async {
        defer {
            if Task.isCancelled { status = .idle }
        }
        
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            status = .error(message: "Bad URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            guard let asset = release.assets.first(where: {
                $0.name.hasSuffix(".dmg") || $0.name.hasSuffix(".zip") || $0.name.hasSuffix(".pkg")
            }),
                  let downloadURL = URL(string: asset.browserDownloadURL),
                  let remote = AppVersion(release.tagName),
                  let current = AppVersion.current else {
                status = .error(message: "Invalid release info")
                return
            }
            
            if remote > current {
                status = .available(version: remote.version, url: downloadURL)
                print("Update available: \(remote.version)")
            } else {
                status = .upToDate
                print("App is up to date")
            }
            
        } catch {
            status = .error(message: error.localizedDescription)
            print("Update check failed: \(error)")
        }
    }
}
