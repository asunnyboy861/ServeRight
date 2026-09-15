import Foundation
import SwiftData

enum RuleEngine {
    static func rebuildDeadlines(for lease: Lease, property: Property?, context: ModelContext) {
        let priorState = Dictionary(uniqueKeysWithValues: lease.deadlineList.map { ($0.ruleID, ($0.statusRaw, $0.servedOn)) })
        lease.deadlineList.forEach { context.delete($0) }
        lease.deadlines = []

        guard let jurisdiction = RuleStore.shared.jurisdiction(for: property?.stateCode ?? "") else { return }
        let leaseContext = lease.context
        let label = property.map { "\($0.nickname) — \($0.street)" } ?? property?.nickname ?? "Lease"

        if let entry = jurisdiction.primaryRule(for: .rentIncrease),
           let percent = lease.increasePercent, percent > 0,
           let event = leaseContext.event(for: entry.baseEvent) {
            appendInstance(for: entry, context: leaseContext, event: event, category: .rentIncrease, lease: lease, label: label, modelContext: context, priorState: priorState)
        }

        if let entry = jurisdiction.primaryRule(for: .depositReturn),
           lease.keysReturnedOn != nil,
           let event = leaseContext.event(for: entry.baseEvent) {
            appendInstance(for: entry, context: leaseContext, event: event, category: .depositReturn, lease: lease, label: label, modelContext: context, priorState: priorState)
        }

        if let entry = jurisdiction.primaryRule(for: .termination),
           let event = leaseContext.event(for: entry.baseEvent) {
            appendInstance(for: entry, context: leaseContext, event: event, category: .termination, lease: lease, label: label, modelContext: context, priorState: priorState)
        }
    }

    static func rebuildAll(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Lease>()
        guard let leases = try? modelContext.fetch(descriptor) else { return }
        for lease in leases {
            rebuildDeadlines(for: lease, property: lease.property, context: modelContext)
        }
        recomputeStatuses(modelContext: modelContext)
    }

    static func recomputeStatuses(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<DeadlineInstance>()
        guard let deadlines = try? modelContext.fetch(descriptor) else { return }
        for deadline in deadlines {
            deadline.recomputeStatus()
            if deadline.status == .served, deadline.servedOn != nil, Date.now.startOfDay >= deadline.statutoryDeadline.startOfDay {
                deadline.status = .compliant
            }
        }
    }

    private static func appendInstance(for entry: RuleEntry, context leaseContext: LeaseContext, event: Date, category: RuleCategory, lease: Lease, label: String, modelContext: ModelContext, priorState: [String: (String, Date?)] = [:]) {
        guard let resolved = DeadlineCalculator.resolve(entry: entry, context: leaseContext) else { return }
        let note = RuleStore.resolvedConditionNote(for: entry, context: leaseContext)
        let instance = DeadlineInstance(
            ruleID: entry.id,
            category: category,
            eventDate: event,
            statutoryDeadline: resolved.deadline,
            bestSendBy: resolved.bestSendBy,
            penaltyText: entry.penalty.penaltyText,
            sourceURL: entry.sourceURL,
            verifiedDate: entry.verifiedDate.parsedDate ?? .now,
            resolvedDays: resolved.days,
            resolvedNote: note,
            leaseLabel: label
        )
        if let (statusRaw, servedOn) = priorState[entry.id] {
            instance.statusRaw = statusRaw
            instance.servedOn = servedOn
        }
        instance.lease = lease
        modelContext.insert(instance)
    }
}

extension String {
    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: self)
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
