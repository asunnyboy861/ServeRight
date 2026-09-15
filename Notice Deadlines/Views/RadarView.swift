import SwiftUI
import SwiftData

struct RadarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var deadlines: [DeadlineInstance]
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var askedPermission = false

    private var sorted: [DeadlineInstance] {
        deadlines.sorted { $0.bestSendBy < $1.bestSendBy }
    }

    private var primary: DeadlineInstance? {
        sorted.first { $0.status == .actionNeeded } ?? sorted.first { $0.status == .upcoming } ?? sorted.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let next = primary {
                        PrimaryCountdownCard(deadline: next)
                        if next.status == .actionNeeded || next.status == .upcoming {
                            GenerateNoticeButton(deadline: next)
                        }
                    } else {
                        EmptyRadarCard()
                    }

                    if sorted.count > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("All Deadlines")
                                .font(.headline)
                            ForEach(sorted) { deadline in
                                NavigationLink(value: deadline.persistentModelID) {
                                    DeadlineRow(deadline: deadline)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Deadline Radar")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                DeadlineDetailView(deadlineID: id)
            }
            .task {
                guard !askedPermission else { return }
                askedPermission = true
                if !UserDefaults.standard.bool(forKey: "notification_permission_asked") {
                    _ = await NotificationScheduler.requestAuthorization()
                    UserDefaults.standard.set(true, forKey: "notification_permission_asked")
                    RuleEngine.recomputeStatuses(modelContext: modelContext)
                    NotificationScheduler.rescheduleAll(deadlines: sorted)
                }
            }
            .onAppear {
                RuleEngine.recomputeStatuses(modelContext: modelContext)
                WidgetBridge.publishSnapshot(deadlines: sorted, isPro: purchaseManager.isPro)
            }
        }
    }
}

struct PrimaryCountdownCard: View {
    let deadline: DeadlineInstance

    private var daysLeft: Int { deadline.daysRemaining }
    private var color: Color {
        switch deadline.status.colorRole {
        case .green: return .green
        case .amber: return .orange
        case .red: return .red
        case .blue: return .blue
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(deadline.category.displayName.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                StatusPill(status: deadline.status)
            }
            Text(daysLeft > 0 ? "\(daysLeft)" : "0")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .accessibilityLabel("\(max(daysLeft, 0)) days remaining, \(deadline.status == .actionNeeded ? "action window open" : "on track")")
            Text(daysLeft > 0 ? "days until best send-by" : "Send it now")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best send-by: \(deadline.bestSendBy.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline.weight(.medium))
                    Text("Statutory deadline: \(deadline.statutoryDeadline.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            RiskAmountCard(penaltyText: deadline.penaltyText)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
    }
}

struct RiskAmountCard: View {
    let penaltyText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text("If you miss it: \(penaltyText)")
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.red.opacity(0.08))
        .cornerRadius(12)
    }
}

struct StatusPill: View {
    let status: DeadlineStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(pillColor.opacity(0.15))
            .foregroundStyle(pillColor)
            .cornerRadius(8)
    }

    private var pillColor: Color {
        switch status.colorRole {
        case .green: return .green
        case .amber: return .orange
        case .red: return .red
        case .blue: return .blue
        }
    }
}

struct GenerateNoticeButton: View {
    let deadline: DeadlineInstance
    @State private var showWizard = false

    var body: some View {
        Button {
            showWizard = true
        } label: {
            Label("Generate Notice", systemImage: "doc.badge.plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: 720)
        .sheet(isPresented: $showWizard) {
            NoticeWizardView(deadline: deadline)
        }
    }
}

struct EmptyRadarCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("You don't need to do anything today")
                .font(.title3.bold())
            Text("Add a property and lease, and your statutory deadlines will appear here with countdowns and reminders.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}

struct DeadlineRow: View {
    let deadline: DeadlineInstance

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(rowColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text("\(max(deadline.daysRemaining, 0))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(rowColor)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(deadline.category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(deadline.leaseLabel) · send by \(deadline.bestSendBy.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var rowColor: Color {
        switch deadline.status.colorRole {
        case .green: return .green
        case .amber: return .orange
        case .red: return .red
        case .blue: return .blue
        }
    }
}

struct DeadlineDetailView: View {
    let deadlineID: PersistentIdentifier
    @Environment(\.modelContext) private var modelContext
    @Query private var deadlines: [DeadlineInstance]

    private var deadline: DeadlineInstance? {
        deadlines.first { $0.persistentModelID == deadlineID }
    }

    var body: some View {
        ScrollView {
            if let deadline {
                VStack(alignment: .leading, spacing: 16) {
                    PrimaryCountdownCard(deadline: deadline)
                    infoSection(deadline)
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Deadline")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoSection(_ deadline: DeadlineInstance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rule Source")
                .font(.headline)
            LabeledRow(label: "Rule ID", value: deadline.ruleID)
            LabeledRow(label: "Notice period", value: "\(deadline.resolvedDays) days")
            if let note = deadline.resolvedNote {
                LabeledRow(label: "Condition applied", value: note)
            }
            LabeledRow(label: "Rule last verified", value: deadline.verifiedDate.formatted(date: .abbreviated, time: .omitted))
            Link("View official statute", destination: URL(string: deadline.sourceURL) ?? URL(string: "https://example.com")!)
                .font(.callout)
            if deadline.isUserOverridden {
                Label("User-defined override, not state default", systemImage: "pencil.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}
