import SwiftUI
import SwiftData

struct CalendarYearView: View {
    @Query private var deadlines: [DeadlineInstance]
    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var selectedPropertyLabel = "All"

    private var labels: [String] {
        ["All"] + Array(Set(deadlines.map(\.leaseLabel))).sorted()
    }

    private var filtered: [DeadlineInstance] {
        deadlines.filter { selectedPropertyLabel == "All" || $0.leaseLabel == selectedPropertyLabel }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Property", selection: $selectedPropertyLabel) {
                        ForEach(labels, id: \.self) { label in
                            Text(label).tag(label)
                        }
                    }
                    .pickerStyle(.menu)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                        ForEach(1...12, id: \.self) { month in
                            MonthCard(year: year, month: month, deadlines: monthDeadlines(month))
                        }
                    }
                    .padding(.horizontal)

                    HStack {
                        Button {
                            year -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        Spacer()
                        Text("\(year)")
                            .font(.headline)
                        Spacer()
                        Button {
                            year += 1
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Compliance Calendar")
        }
    }

    private func monthDeadlines(_ month: Int) -> [DeadlineInstance] {
        filtered.filter {
            Calendar.current.component(.month, from: $0.bestSendBy) == month &&
            Calendar.current.component(.year, from: $0.bestSendBy) == year
        }
    }
}

struct MonthCard: View {
    let year: Int
    let month: Int
    let deadlines: [DeadlineInstance]

    private var monthName: String {
        var comps = DateComponents(); comps.year = year; comps.month = month; comps.day = 1
        return Calendar.current.date(from: comps)?.formatted(.dateTime.month(.wide)) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(monthName)
                .font(.subheadline.bold())
            if deadlines.isEmpty {
                Text("No deadlines")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(deadlines.prefix(4), id: \.persistentModelID) { deadline in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(deadline.status.colorRole == .green ? Color.green : deadline.status.colorRole == .amber ? Color.orange : Color.red)
                            .frame(width: 6, height: 6)
                        Text("\(deadline.category.displayName) · \(deadline.bestSendBy.formatted(.dateTime.day()))")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                if deadlines.count > 4 {
                    Text("+\(deadlines.count - 4) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
