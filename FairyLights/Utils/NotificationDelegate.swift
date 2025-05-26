import Foundation
import UserNotifications

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var updateManager: UpdateManager?
    
    init(updateManager: UpdateManager) {
        self.updateManager = updateManager
        super.init()
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "DOWNLOAD_UPDATE":
            // Capture the update manager directly to avoid self capture issues
            if let manager = updateManager {
                Task { @MainActor in
                    manager.downloadUpdate()
                }
            }
        case "LATER", UNNotificationDefaultActionIdentifier:
            // User tapped "Later" or dismissed - do nothing
            break
        default:
            break
        }
        
        completionHandler()
    }
    
    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner, sound, and badge even when app is active
        completionHandler([.banner, .sound, .badge])
    }
}
