import SwiftUI
import EventKit

class ReminderViewModel: ObservableObject {
    private var eventStore = EKEventStore()
    
    @Published var reminders: [EKReminder] = []
    
    init() {
        self.requestAccessToReminders()
        self.addReminderObserver()
    }
    
    func  requestAccessToReminders() {
        eventStore.requestFullAccessToReminders() { (granted, error) in
            if granted {
                self.loadReminders()
            } else {
                print("WARNING: Not granted to access to reminders.")
                // Check "Privacy - Reminders Full Access Usage Description" in Info.pList
            }
        }
    }
    
    func  loadReminders() {
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { (reminders) in
            DispatchQueue.main.async {
                self.reminders = reminders?.filter { !$0.isCompleted } ?? []
            }
        }
    }

    private func  addReminderObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onReminderChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }

    @objc private func  onReminderChanged(notification: Notification) {
        self.requestAccessToReminders()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
