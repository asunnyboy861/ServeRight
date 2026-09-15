import WidgetKit
import SwiftUI

struct DeadlineEntry: TimelineEntry {
    let date: Date
    let title: String
    let daysLeft: Int?
    let penalty: String
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeadlineEntry {
        DeadlineEntry(date: .now, title: "Deposit return", daysLeft: 12, penalty: "Up to $6,100")
    }

    func getSnapshot(in context: Context, completion: @escaping (DeadlineEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeadlineEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.zzoutuo.ServeRight")
        let title = defaults?.string(forKey: "widgetNextTitle") ?? "No deadline yet"
        let days = defaults?.object(forKey: "widgetNextDays") as? Int
        let penalty = defaults?.string(forKey: "widgetNextPenalty") ?? ""
        let entry = DeadlineEntry(date: .now, title: title, daysLeft: days, penalty: penalty)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct CountdownEntryView: View {
    var entry: DeadlineEntry

    var body: some View {
        VStack(spacing: 4) {
            if let days = entry.daysLeft {
                Text("\(days)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                Text(days == 1 ? "day left" : "days left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "checkmark.seal")
                    .font(.title)
                Text("All set")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(entry.title)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .containerBackground(for: .widget) {
            Color(white: 0.05)
        }
        .widgetAccentable()
    }
}

@main
struct ServeRightWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ServeRightCountdownWidget()
    }
}

struct ServeRightCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ServeRightCountdown", provider: CountdownProvider()) { entry in
            CountdownEntryView(entry: entry)
        }
        .configurationDisplayName("Notice Deadline")
        .description("Countdown to your next statutory notice deadline.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
