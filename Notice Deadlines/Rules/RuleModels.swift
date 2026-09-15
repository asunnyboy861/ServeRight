import Foundation

enum RuleCategory: String, Codable, CaseIterable, Identifiable {
    case rentIncrease = "rent_increase"
    case depositReturn = "deposit_return"
    case depositCap = "deposit_cap"
    case termination = "termination"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rentIncrease: return "Rent Increase Notice"
        case .depositReturn: return "Deposit Return"
        case .depositCap: return "Deposit Cap"
        case .termination: return "Termination Notice"
        }
    }

    var icon: String {
        switch self {
        case .rentIncrease: return "chart.line.uptrend.xyaxis"
        case .depositReturn: return "dollarsign.arrow.circlepath"
        case .depositCap: return "scalemass.fill"
        case .termination: return "envelope.badge"
        }
    }

    var humanName: String { displayName }
}

struct PenaltySpec: Codable {
    let type: String
    let fixed: Double?
    let multiplier: Double?
    let plusAttorneyFees: Bool?
    let citation: String

    enum CodingKeys: String, CodingKey {
        case type, fixed, multiplier, citation
        case plusAttorneyFees = "plus_attorney_fees"
    }
}

struct RuleCondition: Codable {
    let field: String
    let op: String
    let value: ConditionValue
    let days: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case field, op, value, days, note
    }
}

enum ConditionValue: Codable {
    case bool(Bool)
    case number(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported condition value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let b): try container.encode(b)
        case .number(let n): try container.encode(n)
        }
    }
}

struct StrictDecoder {
    struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    static func validate(keys: [CodingKey], allowed: Set<String>, typeName: String) throws {
        for key in keys where !allowed.contains(key.stringValue) {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unknown field '\(key.stringValue)' in \(typeName)"))
        }
    }

}

struct RuleEntry: Codable, Identifiable {
    let id: String
    let trigger: String
    let timing: String
    let days: Int?
    let calendar: String
    let baseEvent: String
    let conditions: [RuleCondition]
    let capMonths: Double?
    let penalty: PenaltySpec
    let sourceURL: String
    let verifiedDate: String
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, trigger, timing, days, calendar, conditions, penalty, note
        case baseEvent = "base_event"
        case capMonths = "cap_months"
        case sourceURL = "source_url"
        case verifiedDate = "verified_date"
    }

    static let allowedKeys: Set<String> = ["id", "trigger", "timing", "days", "calendar", "base_event", "conditions", "cap_months", "penalty", "source_url", "verified_date", "note"]

    init(from decoder: Decoder) throws {
        try StrictDecoder.validate(keys: decoder.container(keyedBy: StrictDecoder.AnyKey.self).allKeys, allowed: Self.allowedKeys, typeName: "RuleEntry")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        trigger = try container.decode(String.self, forKey: .trigger)
        timing = try container.decode(String.self, forKey: .timing)
        days = try container.decodeIfPresent(Int.self, forKey: .days)
        calendar = try container.decode(String.self, forKey: .calendar)
        baseEvent = try container.decode(String.self, forKey: .baseEvent)
        conditions = try container.decode([RuleCondition].self, forKey: .conditions)
        capMonths = try container.decodeIfPresent(Double.self, forKey: .capMonths)
        penalty = try container.decode(PenaltySpec.self, forKey: .penalty)
        sourceURL = try container.decode(String.self, forKey: .sourceURL)
        verifiedDate = try container.decode(String.self, forKey: .verifiedDate)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }

    init(id: String, trigger: String, timing: String, days: Int?, calendar: String, baseEvent: String, conditions: [RuleCondition], capMonths: Double?, penalty: PenaltySpec, sourceURL: String, verifiedDate: String, note: String? = nil) {
        self.id = id
        self.trigger = trigger
        self.timing = timing
        self.days = days
        self.calendar = calendar
        self.baseEvent = baseEvent
        self.conditions = conditions
        self.capMonths = capMonths
        self.penalty = penalty
        self.sourceURL = sourceURL
        self.verifiedDate = verifiedDate
        self.note = note
    }
}

struct Jurisdiction: Codable, Identifiable {
    let code: String
    let name: String
    let categories: [String: [RuleEntry]]

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code, name, categories
    }

    static let allowedKeys: Set<String> = ["code", "name", "categories"]

    init(from decoder: Decoder) throws {
        try StrictDecoder.validate(keys: decoder.container(keyedBy: StrictDecoder.AnyKey.self).allKeys, allowed: Self.allowedKeys, typeName: "Jurisdiction")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        categories = try container.decode([String: [RuleEntry]].self, forKey: .categories)
    }

    init(code: String, name: String, categories: [String: [RuleEntry]]) {
        self.code = code
        self.name = name
        self.categories = categories
    }

    func rules(for category: RuleCategory) -> [RuleEntry] {
        categories[category.rawValue] ?? []
    }

    func primaryRule(for category: RuleCategory) -> RuleEntry? {
        rules(for: category).first
    }
}

struct RulesDocument: Codable {
    let schemaVersion: String
    let jurisdictions: [Jurisdiction]

    enum CodingKeys: String, CodingKey {
        case jurisdictions
        case schemaVersion = "schema_version"
    }

    static let allowedKeys: Set<String> = ["schema_version", "jurisdictions"]

    init(from decoder: Decoder) throws {
        try StrictDecoder.validate(keys: decoder.container(keyedBy: StrictDecoder.AnyKey.self).allKeys, allowed: Self.allowedKeys, typeName: "RulesDocument")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        jurisdictions = try container.decode([Jurisdiction].self, forKey: .jurisdictions)
    }

    init(schemaVersion: String, jurisdictions: [Jurisdiction]) {
        self.schemaVersion = schemaVersion
        self.jurisdictions = jurisdictions
    }
}
