import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("checkForUpdatesAutomatically") var checkForUpdatesAutomatically: Bool = false
    
    @Published var isCheckingForUpdates: Bool = false
    
    // Persistent storage for last check date
    @AppStorage("lastUpdateCheck") private var lastUpdateCheck: Double = 0 // Stores Date as TimeInterval
    
    private let updateCheckInterval: TimeInterval = 86400 // 24 hours in seconds
    
    // Schedules the next update check if automatic checking is enabled
    func scheduleNextUpdateCheck(checkForUpdates: @escaping () -> Void) {
        guard checkForUpdatesAutomatically else { return }
        
        let lastCheckDate = Date(timeIntervalSince1970: lastUpdateCheck)
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheckDate)
        
        if timeSinceLastCheck >= updateCheckInterval {
            // Perform the update check
            checkForUpdates()
            // Update the last check time
            lastUpdateCheck = Date().timeIntervalSince1970
        }
    }
}
