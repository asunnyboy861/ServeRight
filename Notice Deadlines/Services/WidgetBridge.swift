import Foundation

enum WidgetBridge {
    static let appGroupID = "group.com.zzoutuo.ServeRight"

    static func publishSnapshot(deadlines: [DeadlineInstance], isPro: Bool) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let limit = isPro ? max(deadlines.count, 1) : FreeLimits.maxFreeWidgetDeadlines
        let sorted = deadlines
            .filter { $0.status == .upcoming || $0.status == .actionNeeded }
            .sorted { $0.bestSendBy < $1.bestSendBy }
        guard let next = sorted.first else {
            defaults.set("All caught up", forKey: "widgetNextTitle")
            defaults.removeObject(forKey: "widgetNextDays")
            defaults.set("", forKey: "widgetNextPenalty")
            return
        }
        defaults.set(next.category.displayName, forKey: "widgetNextTitle")
        defaults.set(next.daysRemaining, forKey: "widgetNextDays")
        defaults.set(next.penaltyText, forKey: "widgetNextPenalty")
        _ = limit
    }
}
