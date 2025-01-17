import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("checkForUpdatesAutomatically") var checkForUpdatesAutomatically: Bool = false
    @Published var isCheckingForUpdates: Bool = false
    @AppStorage("lastUpdateCheck") private var lastUpdateCheck: Double = 0

    private let updateCheckInterval: TimeInterval = 86400

    func scheduleNextUpdateCheck(checkForUpdates: @escaping () -> Void) {
        guard checkForUpdatesAutomatically else { return }

        let lastCheckDate = Date(timeIntervalSince1970: lastUpdateCheck)
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheckDate)

        if timeSinceLastCheck >= updateCheckInterval {
            checkForUpdates()
            lastUpdateCheck = Date().timeIntervalSince1970
        }
    }
}
