import Foundation

enum HolidayCalendar {
    static let federalHolidays: Set<Date> = {
        var set = Set<Date>()
        let cal = Calendar.current
        func fixed(_ y: Int, _ m: Int, _ d: Int) {
            if let date = cal.date(from: DateComponents(year: y, month: m, day: d)) {
                set.insert(date.startOfDay)
            }
        }
        func nthWeekday(_ n: Int, weekday: Int, month: Int, year: Int) {
            let comps = DateComponents(year: year, month: month, weekday: weekday, weekdayOrdinal: n)
            if let date = cal.date(from: comps) {
                set.insert(date.startOfDay)
            }
        }
        func lastWeekday(weekday: Int, month: Int, year: Int) {
            let lastDay = DateComponents(year: year, month: month + 1, day: 0)
            guard let last = cal.date(from: lastDay) else { return }
            var candidate = last.startOfDay
            while cal.component(.weekday, from: candidate) != weekday {
                candidate = cal.date(byAdding: .day, value: -1, to: candidate)!
            }
            set.insert(candidate)
        }
        for year in [2025, 2026, 2027] {
            fixed(year, 1, 1)
            fixed(year, 6, 19)
            fixed(year, 7, 4)
            fixed(year, 11, 11)
            fixed(year, 12, 25)
            nthWeekday(3, weekday: 2, month: 1, year: year)
            nthWeekday(3, weekday: 2, month: 2, year: year)
            lastWeekday(weekday: 2, month: 5, year: year)
            nthWeekday(1, weekday: 2, month: 9, year: year)
            nthWeekday(4, weekday: 5, month: 11, year: year)
        }
        return set
    }()

    static func isHoliday(_ date: Date) -> Bool {
        federalHolidays.contains(date.startOfDay)
    }

    static func isBusinessDay(_ date: Date) -> Bool {
        !Calendar.current.isDateInWeekend(date) && !isHoliday(date)
    }
}

enum DeadlineCalculator {
    static let mailBufferDays = 5

    static func statutoryDeadline(from base: Date, days: Int, calendar: String) -> Date {
        let cal = Calendar.current
        let start = base.startOfDay
        if calendar == "business_days" {
            var date = start
            var remaining = days
            while remaining > 0 {
                date = cal.date(byAdding: .day, value: 1, to: date)!
                if HolidayCalendar.isBusinessDay(date) {
                    remaining -= 1
                }
            }
            return date
        }
        return cal.date(byAdding: .day, value: days, to: start)!
    }

    static func sendDeadlineBefore(event: Date, days: Int, calendar: String) -> Date {
        let cal = Calendar.current
        var date = event.startOfDay
        var remaining = days
        while remaining > 0 {
            date = cal.date(byAdding: .day, value: -1, to: date)!
            if calendar == "business_days" {
                if HolidayCalendar.isBusinessDay(date) {
                    remaining -= 1
                }
            } else {
                remaining -= 1
            }
        }
        return date
    }

    static func bestSendBy(from deadline: Date) -> Date {
        let cal = Calendar.current
        var date = cal.date(byAdding: .day, value: -mailBufferDays, to: deadline.startOfDay)!
        while !HolidayCalendar.isBusinessDay(date) {
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return date
    }

    static func resolve(entry: RuleEntry, context: LeaseContext) -> (event: Date?, deadline: Date, bestSendBy: Date, days: Int)? {
        var days = RuleStore.resolveDays(for: entry, context: context)
        if let stored = UserDefaults.standard.object(forKey: "override_\(entry.id)") as? Int, stored > 0 {
            days = stored
        }
        guard let days else { return nil }
        switch entry.timing {
        case "before_event":
            guard let event = context.event(for: entry.baseEvent) else { return nil }
            let sendDeadline = sendDeadlineBefore(event: event, days: days, calendar: entry.calendar)
            return (event, sendDeadline, bestSendBy(from: sendDeadline), days)
        case "after_trigger":
            guard let base = context.event(for: entry.baseEvent) else { return nil }
            let deadline = statutoryDeadline(from: base, days: days, calendar: entry.calendar)
            return (base, deadline, bestSendBy(from: deadline), days)
        default:
            return nil
        }
    }
}
