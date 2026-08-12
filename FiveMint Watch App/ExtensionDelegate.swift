import WatchKit
import UserNotifications

class ExtensionDelegate: NSObject, WKExtensionDelegate, UNUserNotificationCenterDelegate {
    // This object is enabled by @WKExtensionDelegateAdaptor

    func applicationDidFinishLaunching() {

        // Enable to call userNotificationCenter
        let  notifications = UNUserNotificationCenter.current()
        notifications.delegate = self
        notifications.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {

                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
        }
    }

    func applicationWillTerminate() {
        let  notifications = UNUserNotificationCenter.current()
        notifications.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {

                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
        }
    }

    var  previousContentTitle = ""

    func userNotificationCenter(_ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.trigger is UNTimeIntervalNotificationTrigger {
            var  notificationType: String
            let  subtitle = notification.request.content.subtitle
            if subtitle == "knock" {
                notificationType = "knock"
            } else if subtitle == "5mint(1)" {
                notificationType = "ready"
            } else if subtitle == "5mint(2)" {
                notificationType = "ready"
            } else if subtitle == "5mint(3)" {
                notificationType = "start"
            } else if subtitle == "5mint(4)" {
                notificationType = "start"
            } else if subtitle == "5mint(9)" {
                notificationType = "off"
            } else {  // if subtitle == "advice" {
                notificationType = "advice"
            }
            if notification.request.content.subtitle != self.previousContentTitle {
                self.previousContentTitle = notification.request.content.subtitle
                if notificationType == "knock"  ||  notificationType == "advice" {

                    WKInterfaceDevice.current().play(.click)  // Play by not notification
                } else if notificationType == "ready" {
                    WKInterfaceDevice.current().play(.success)
                } else if notificationType == "start" {
                    WKInterfaceDevice.current().play(.directionDown)
                } else if notificationType == "off" {
                    WKInterfaceDevice.current().play(.failure)
                }
            }

            if notificationType == "advice" {  // Normal case
                completionHandler([.banner])
            } else {
                completionHandler([])  // completionHandler([.banner, .sound])
            }
        }
    }
}
