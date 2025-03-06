import AppKit
import Sparkle
import UserNotifications

class GentleUpdaterDelegate: NSObject, SPUStandardUserDriverDelegate {
    weak var updaterController: SPUStandardUpdaterController?
    
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }
    
    var window: NSWindow? {
        return nil
    }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func presentInstallerInFrontOfWindow(_ installerPath: String, window: NSWindow) {
        let url = URL(fileURLWithPath: installerPath)
        NSWorkspace.shared.open(url)
    }
    
    func showUpdateScheduledWithInformativeText(_ informativeText: String) {
        DispatchQueue.main.async {
            let content = UNMutableNotificationContent()
            content.title = "Software Update Available"
            content.body = informativeText
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "com.fairylights.updateNotification",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing notification: \(error)")
                }
            }
        }
    }
    
    func hideUpdateScheduled() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}
