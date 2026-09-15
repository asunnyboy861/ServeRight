import Foundation
import UserNotifications

enum NotificationScheduler {
    static let offsets: [Int: String] = [14: "2 weeks left", 7: "1 week left", 3: "3 days left", 1: "TOMORROW"]

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func rescheduleAll(deadlines: [DeadlineInstance]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for deadline in deadlines {
            schedule(for: deadline)
        }
    }

    static func schedule(for deadline: DeadlineInstance) {
        guard deadline.status == .upcoming || deadline.status == .actionNeeded else { return }
        let center = UNUserNotificationCenter.current()
        for (offset, urgency) in offsets {
            guard let fireDate = Calendar.current.date(byAdding: .day, value: -offset, to: deadline.bestSendBy) else { continue }
            guard fireDate > Date.now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "\(urgency): \(deadline.category.displayName)"
            content.body = "Best send-by: \(deadline.bestSendBy.formatted(date: .abbreviated, time: .omitted)). Penalty: \(deadline.penaltyText)."
            content.sound = .default
            content.userInfo = ["ruleID": deadline.ruleID]
            var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
            components.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "\(deadline.ruleID)-\(Int(deadline.statutoryDeadline.timeIntervalSince1970))-\(offset)", content: content, trigger: trigger)
            center.add(request)
        }
    }
}
