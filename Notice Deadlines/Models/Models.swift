import Foundation
import SwiftData

@Model
final class Property {
    var nickname: String = ""
    var street: String = ""
    var stateCode: String = ""
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Lease.property)
    var leases: [Lease]? = []

    init(nickname: String, street: String, stateCode: String) {
        self.nickname = nickname
        self.street = street
        self.stateCode = stateCode
        self.createdAt = .now
    }

    var leaseList: [Lease] { leases ?? [] }
}

@Model
final class Lease {
    var tenantName: String = ""
    var monthlyRent: Double = 0
    var depositAmount: Double = 0
    var startDate: Date = Date.now
    var endDate: Date?
    var tenancyYears: Double = 0
    var forwardingAddressReceivedOn: Date?
    var keysReturnedOn: Date?
    var increasePercent: Double?
    var increaseEffectiveDate: Date?
    var deductionsClaimed: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \DeadlineInstance.lease)
    var deadlines: [DeadlineInstance]? = []

    @Relationship
    var property: Property?

    init(tenantName: String,
         monthlyRent: Double,
         depositAmount: Double,
         startDate: Date,
         endDate: Date? = nil,
         tenancyYears: Double = 0,
         forwardingAddressReceivedOn: Date? = nil,
         keysReturnedOn: Date? = nil,
         increasePercent: Double? = nil,
         increaseEffectiveDate: Date? = nil,
         deductionsClaimed: Bool = false) {
        self.tenantName = tenantName
        self.monthlyRent = monthlyRent
        self.depositAmount = depositAmount
        self.startDate = startDate
        self.endDate = endDate
        self.tenancyYears = tenancyYears
        self.forwardingAddressReceivedOn = forwardingAddressReceivedOn
        self.keysReturnedOn = keysReturnedOn
        self.increasePercent = increasePercent
        self.increaseEffectiveDate = increaseEffectiveDate
        self.deductionsClaimed = deductionsClaimed
    }

    var deadlineList: [DeadlineInstance] { deadlines ?? [] }

    var context: LeaseContext {
        var leaseEnd = endDate
        if leaseEnd == nil {
            var next = startDate.startOfDay
            while next <= Date.now.startOfDay {
                next = Calendar.current.date(byAdding: .month, value: 1, to: next) ?? next.addingTimeInterval(30 * 86400)
            }
            leaseEnd = next
        }
        return LeaseContext(
            increasePercent: increasePercent,
            tenancyYears: tenancyYears,
            deductionsClaimed: deductionsClaimed,
            forwardingAddressReceived: forwardingAddressReceivedOn != nil,
            keysReturnedDate: keysReturnedOn,
            forwardingDate: forwardingAddressReceivedOn,
            leaseEndDate: leaseEnd,
            increaseEffectiveDate: increaseEffectiveDate
        )
    }

    var isMonthToMonth: Bool { endDate == nil }
}

@Model
final class DeadlineInstance {
    var ruleID: String = ""
    var categoryRaw: String = ""
    var eventDate: Date = Date(timeIntervalSince1970: 0)
    var statutoryDeadline: Date = Date(timeIntervalSince1970: 0)
    var bestSendBy: Date = Date(timeIntervalSince1970: 0)
    var penaltyText: String = ""
    var statusRaw: String = ""
    var servedOn: Date?
    var sourceURL: String = ""
    var verifiedDate: Date = Date(timeIntervalSince1970: 0)
    var isUserOverridden: Bool = false
    var overrideNote: String?
    var resolvedDays: Int = 0
    var resolvedNote: String?
    var leaseLabel: String = ""

    @Relationship
    var lease: Lease?

    init(ruleID: String,
         category: RuleCategory,
         eventDate: Date,
         statutoryDeadline: Date,
         bestSendBy: Date,
         penaltyText: String,
         sourceURL: String,
         verifiedDate: Date,
         resolvedDays: Int,
         resolvedNote: String? = nil,
         leaseLabel: String = "") {
        self.ruleID = ruleID
        self.categoryRaw = category.rawValue
        self.eventDate = eventDate
        self.statutoryDeadline = statutoryDeadline
        self.bestSendBy = bestSendBy
        self.penaltyText = penaltyText
        self.statusRaw = DeadlineStatus.upcoming.rawValue
        self.servedOn = nil
        self.sourceURL = sourceURL
        self.verifiedDate = verifiedDate
        self.isUserOverridden = false
        self.overrideNote = nil
        self.resolvedDays = resolvedDays
        self.resolvedNote = resolvedNote
        self.leaseLabel = leaseLabel
    }

    var category: RuleCategory {
        get { RuleCategory(rawValue: categoryRaw) ?? .depositReturn }
        set { categoryRaw = newValue.rawValue }
    }

    var status: DeadlineStatus {
        get { DeadlineStatus(rawValue: statusRaw) ?? .upcoming }
        set { statusRaw = newValue.rawValue }
    }

    func recomputeStatus(now: Date = .now) {
        switch status {
        case .served, .compliant:
            return
        default:
            let daysLeft = Calendar.current.dateComponents([.day], from: now.startOfDay, to: bestSendBy.startOfDay).day ?? 0
            status = daysLeft <= 0 ? .actionNeeded : .upcoming
        }
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: bestSendBy.startOfDay).day ?? 0
    }
}

enum DeadlineStatus: String, Codable {
    case upcoming
    case actionNeeded = "action_needed"
    case served
    case compliant
    case expired

    var displayName: String {
        switch self {
        case .upcoming: return "On Track"
        case .actionNeeded: return "Action Needed"
        case .served: return "Served"
        case .compliant: return "Compliant"
        case .expired: return "Expired"
        }
    }

    var colorRole: ColorRole {
        switch self {
        case .upcoming, .compliant: return .green
        case .actionNeeded: return .amber
        case .served: return .blue
        case .expired: return .red
        }
    }
}

enum ColorRole {
    case green, amber, red, blue
}

@Model
final class LetterArchive {
    var letterTypeRaw: String = ""
    var tenantName: String = ""
    var propertyLabel: String = ""
    var createdAt: Date = Date.now
    var pdfData: Data = Data()
    var statuteCitation: String = ""
    var deliveryMethod: String = ""

    init(letterType: LetterType, tenantName: String, propertyLabel: String, pdfData: Data, statuteCitation: String, deliveryMethod: String) {
        self.letterTypeRaw = letterType.rawValue
        self.tenantName = tenantName
        self.propertyLabel = propertyLabel
        self.createdAt = .now
        self.pdfData = pdfData
        self.statuteCitation = statuteCitation
        self.deliveryMethod = deliveryMethod
    }

    var letterType: LetterType {
        LetterType(rawValue: letterTypeRaw) ?? .rentIncrease
    }
}

enum LetterType: String, Codable, CaseIterable, Identifiable {
    case rentIncrease = "rent_increase"
    case depositItemizedReturn = "deposit_itemized_return"
    case nonRenewal = "non_renewal"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rentIncrease: return "Rent Increase Notice"
        case .depositItemizedReturn: return "Deposit Return (Itemized)"
        case .nonRenewal: return "Non-Renewal Notice"
        }
    }

    var category: RuleCategory {
        switch self {
        case .rentIncrease: return .rentIncrease
        case .depositItemizedReturn: return .depositReturn
        case .nonRenewal: return .termination
        }
    }
}
