import Foundation

struct RuleStore {
    static let shared: RuleStore = {
        do {
            return try RuleStore()
        } catch {
            fatalError("Rules bundle data is invalid: \(error)")
        }
    }()

    let document: RulesDocument

    init(document: RulesDocument) {
        self.document = document
    }

    init() throws {
        guard let url = Bundle.main.url(forResource: "rules_2026_1", withExtension: "json") else {
            throw NSError(domain: "RuleStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "rules_2026_1.json not found in bundle"])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        document = try decoder.decode(RulesDocument.self, from: data)
    }

    var version: String { document.schemaVersion }

    var jurisdictions: [Jurisdiction] {
        document.jurisdictions.sorted { $0.name < $1.name }
    }

    func jurisdiction(for code: String) -> Jurisdiction? {
        document.jurisdictions.first { $0.code == code }
    }

    static func resolveDays(for entry: RuleEntry, context: LeaseContext) -> Int? {
        if entry.timing == "reference" { return nil }
        var days = entry.days
        for condition in entry.conditions {
            if condition.matches(context: context) {
                days = condition.days
                break
            }
        }
        return days
    }

    static func resolvedConditionNote(for entry: RuleEntry, context: LeaseContext) -> String? {
        for condition in entry.conditions where condition.matches(context: context) {
            return condition.note
        }
        return entry.note
    }
}

struct LeaseContext {
    var increasePercent: Double?
    var tenancyYears: Double
    var deductionsClaimed: Bool
    var forwardingAddressReceived: Bool
    var keysReturnedDate: Date?
    var forwardingDate: Date?
    var leaseEndDate: Date?
    var increaseEffectiveDate: Date?

    init(increasePercent: Double? = nil,
         tenancyYears: Double = 0,
         deductionsClaimed: Bool = false,
         forwardingAddressReceived: Bool = false,
         keysReturnedDate: Date? = nil,
         forwardingDate: Date? = nil,
         leaseEndDate: Date? = nil,
         increaseEffectiveDate: Date? = nil) {
        self.increasePercent = increasePercent
        self.tenancyYears = tenancyYears
        self.deductionsClaimed = deductionsClaimed
        self.forwardingAddressReceived = forwardingAddressReceived
        self.keysReturnedDate = keysReturnedDate
        self.forwardingDate = forwardingDate
        self.leaseEndDate = leaseEndDate
        self.increaseEffectiveDate = increaseEffectiveDate
    }

    func value(for field: String) -> Double? {
        switch field {
        case "increase_percent": return increasePercent
        case "tenancy_years": return tenancyYears
        case "deductions_claimed": return deductionsClaimed ? 1 : 0
        case "forwarding_address_received": return forwardingAddressReceived ? 1 : 0
        default: return nil
        }
    }

    func event(for baseEvent: String) -> Date? {
        switch baseEvent {
        case "keys_returned", "surrender", "vacate_date":
            return keysReturnedDate
        case "later_of_keys_forwarding":
            guard let keys = keysReturnedDate else { return nil }
            guard let forwarding = forwardingDate, forwarding > keys else { return keys }
            return forwarding
        case "lease_end", "lease_end_date":
            return leaseEndDate
        case "increase_effective", "increase_effective_date":
            return increaseEffectiveDate
        default:
            return nil
        }
    }
}

extension RuleCondition {
    func matches(context: LeaseContext) -> Bool {
        guard let actual = context.value(for: field) else { return false }
        switch value {
        case .bool(let b):
            let actualBool = actual != 0
            return op == "eq" ? actualBool == b : false
        case .number(let n):
            switch op {
            case "eq": return actual == n
            case "gt": return actual > n
            case "gte": return actual >= n
            case "lte": return actual <= n
            default: return false
            }
        }
    }
}

extension PenaltySpec {
    var penaltyText: String {
        var parts: [String] = []
        switch type {
        case "fixed_plus_multiplier":
            if let fixed = fixed { parts.append("$\(Int(fixed))") }
            if let m = multiplier { parts.append("\(formatMultiplier(m)) the deposit") }
            if plusAttorneyFees == true { parts.append("attorney fees") }
        case "treble_if_bad_faith", "multiplier_if_bad_faith", "multiplier_if_willful", "multiplier_fixed", "forfeit_plus_multiplier":
            if let m = multiplier { parts.append("up to \(formatMultiplier(m)) the deposit") }
            if plusAttorneyFees == true { parts.append("attorney fees") }
        case "forfeit_deductions_plus_treble_if_willful":
            parts.append("forfeited deductions")
            parts.append("treble damages if willful")
        case "forfeit_deductions", "excess_cap_forfeit":
            parts.append("forfeits right to deduct")
        case "informational":
            return "Comply with the statutory notice period (\(citation))"
        default:
            parts.append("statutory penalty applies")
        }
        let base = parts.isEmpty ? "statutory penalty" : parts.joined(separator: " + ")
        return base + " (\(citation))"
    }

    private func formatMultiplier(_ m: Double) -> String {
        if m == m.rounded() { return "\(Int(m))×" }
        return "\(m)×"
    }
}
