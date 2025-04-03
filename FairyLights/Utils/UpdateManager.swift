import SwiftUI

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
    
    func checkForUpdates(completion: ((UpdateStatus) -> Void)? = nil) {
        status = .checking
        Task {
            await fetchLatestRelease()
            completion?(status)
        }
    }
    
    func downloadUpdate() {
        if case let .available(_, url) = status {
            NSWorkspace.shared.open(url)
        }
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
            
            status = remote > current
            ? .available(version: remote.version, url: downloadURL)
            : .upToDate
            
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }
}
