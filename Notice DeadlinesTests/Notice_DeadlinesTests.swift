import XCTest
import SwiftData
@testable import Notice_Deadlines

final class RulesGoldenTests: XCTestCase {
    let store = try! RuleStore()
    let cal = Calendar.current

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!.startOfDay
    }

    private func assertDate(_ actual: Date, _ y: Int, _ m: Int, _ d: Int, _ label: String, line: UInt = #line) {
        let comps = cal.dateComponents([.year, .month, .day], from: actual)
        XCTAssertEqual(comps.year, y, "\(label) year", line: line)
        XCTAssertEqual(comps.month, m, "\(label) month", line: line)
        XCTAssertEqual(comps.day, d, "\(label) day", line: line)
    }

    private func resolve(_ code: String, _ category: RuleCategory, context: LeaseContext) throws -> (event: Date, deadline: Date, bestSendBy: Date, days: Int) {
        let jurisdiction = store.jurisdiction(for: code)
        let entry = try XCTUnwrap(jurisdiction?.primaryRule(for: category), "missing rule for \(code)")
        guard let event = context.event(for: entry.baseEvent) else {
            throw NSError(domain: "test", code: 1)
        }
        let resolved = try XCTUnwrap(DeadlineCalculator.resolve(entry: entry, context: context))
        return (event, resolved.deadline, resolved.bestSendBy, resolved.days)
    }

    func testUserOverrideAffectsEngine() throws {
        UserDefaults.standard.set(45, forKey: "override_TX-DEP-RET-01")
        defer { UserDefaults.standard.removeObject(forKey: "override_TX-DEP-RET-01") }
        let r = try resolve("TX", .depositReturn, context: LeaseContext(keysReturnedDate: date(2026, 3, 1)))
        XCTAssertEqual(r.days, 45, "override must replace state default")
        assertDate(r.deadline, 2026, 4, 15, "override deadline")
    }

    func testRebuildPreservesServedStatus() throws {
        let schema = Schema([Property.self, Lease.self, DeadlineInstance.self, LetterArchive.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let property = Property(nickname: "Oak", street: "1 Main St", stateCode: "TX")
        context.insert(property)
        let lease = Lease(tenantName: "Bob", monthlyRent: 1500, depositAmount: 1500, startDate: date(2026, 1, 1), endDate: date(2026, 12, 31))
        lease.property = property
        context.insert(lease)

        RuleEngine.rebuildDeadlines(for: lease, property: property, context: context)
        let before = try XCTUnwrap(lease.deadlineList.first { $0.category == .termination })
        before.status = .served
        before.servedOn = date(2026, 6, 1)

        RuleEngine.rebuildDeadlines(for: lease, property: property, context: context)
        let after = try XCTUnwrap(lease.deadlineList.first { $0.category == .termination })
        XCTAssertEqual(after.status, .served, "served status must survive a rebuild")
        XCTAssertEqual(after.servedOn, date(2026, 6, 1))
    }

    func testRulesVersion() {
        XCTAssertEqual(store.version, "2026.1")
    }

    func testAllJurisdictionsPresent() {
        XCTAssertEqual(store.document.jurisdictions.count, 51)
    }

    func testEveryJurisdictionHasAllCategories() {
        for jurisdiction in store.document.jurisdictions {
            for category in RuleCategory.allCases {
                XCTAssertFalse(jurisdiction.rules(for: category).isEmpty, "\(jurisdiction.code) missing \(category.rawValue)")
            }
        }
    }

    func testStrictDecodeThrowsOnUnknownField() throws {
        let json = """
        {"schema_version":"x","jurisdictions":[{"code":"TX","name":"Texas","bogus_field":1,"categories":{}}]}
        """
        XCTAssertThrowsError(try JSONDecoder().decode(RulesDocument.self, from: Data(json.utf8)))
    }

    func testTxDualTriggerLaterOf() throws {
        let r = try resolve("TX", .depositReturn, context: LeaseContext(keysReturnedDate: date(2026, 1, 10), forwardingDate: date(2026, 1, 12)))
        assertDate(r.deadline, 2026, 2, 11, "TX later_of deadline")
    }

    func testTxKeysOnlyTrigger() throws {
        let r = try resolve("TX", .depositReturn, context: LeaseContext(keysReturnedDate: date(2026, 3, 1)))
        assertDate(r.deadline, 2026, 3, 31, "TX keys-only deadline")
        assertDate(r.bestSendBy, 2026, 3, 26, "TX best send-by")
    }

    func testFlDualTrackNoDeductions() throws {
        let r = try resolve("FL", .depositReturn, context: LeaseContext(deductionsClaimed: false, keysReturnedDate: date(2026, 1, 1)))
        assertDate(r.deadline, 2026, 1, 16, "FL 15-day deadline")
        assertDate(r.bestSendBy, 2026, 1, 9, "FL best send-by (weekend shift)")
    }

    func testFlDualTrackDeductions() throws {
        let r = try resolve("FL", .depositReturn, context: LeaseContext(deductionsClaimed: true, keysReturnedDate: date(2026, 1, 1)))
        assertDate(r.deadline, 2026, 1, 31, "FL 30-day deduction deadline")
    }

    func testAzBusinessDays() throws {
        let r = try resolve("AZ", .depositReturn, context: LeaseContext(keysReturnedDate: date(2026, 3, 2)))
        assertDate(r.deadline, 2026, 3, 20, "AZ 14 business days")
    }

    func testAzBusinessDaysSkipJuneteenth() throws {
        let r = try resolve("AZ", .depositReturn, context: LeaseContext(keysReturnedDate: date(2026, 6, 1)))
        assertDate(r.deadline, 2026, 6, 22, "AZ skips Juneteenth holiday")
    }

    func testCaIncreaseUnderTenPercent() throws {
        let r = try resolve("CA", .rentIncrease, context: LeaseContext(increasePercent: 5, increaseEffectiveDate: date(2026, 7, 1)))
        assertDate(r.deadline, 2026, 6, 1, "CA 30-day send deadline")
        assertDate(r.bestSendBy, 2026, 5, 27, "CA best send-by")
    }

    func testCaIncreaseOverTenPercent() throws {
        let r = try resolve("CA", .rentIncrease, context: LeaseContext(increasePercent: 12, increaseEffectiveDate: date(2026, 7, 1)))
        assertDate(r.deadline, 2026, 4, 2, "CA 90-day send deadline")
        assertDate(r.bestSendBy, 2026, 3, 27, "CA best send-by (weekend shift)")
    }

    func testNyTenancyTierTwoYears() throws {
        let r = try resolve("NY", .rentIncrease, context: LeaseContext(increasePercent: 4, tenancyYears: 2, increaseEffectiveDate: date(2026, 8, 1)))
        XCTAssertEqual(r.days, 90, "NY 2+ year tier")
        assertDate(r.deadline, 2026, 5, 3, "NY send deadline")
        assertDate(r.bestSendBy, 2026, 4, 28, "NY best send-by")
    }

    func testNyTenancyTierUnderOneYear() throws {
        let r = try resolve("NY", .rentIncrease, context: LeaseContext(increasePercent: 4, tenancyYears: 0.5, increaseEffectiveDate: date(2026, 8, 1)))
        XCTAssertEqual(r.days, 30, "NY under-1-year tier")
    }

    func testHiFortyFiveDayTermination() throws {
        let r = try resolve("HI", .termination, context: LeaseContext(leaseEndDate: date(2026, 9, 30)))
        XCTAssertEqual(r.days, 45)
        assertDate(r.deadline, 2026, 8, 16, "HI send deadline")
        assertDate(r.bestSendBy, 2026, 8, 11, "HI best send-by")
    }

    func testCoTwentyOneDayTermination() throws {
        let r = try resolve("CO", .termination, context: LeaseContext(leaseEndDate: date(2026, 10, 31)))
        XCTAssertEqual(r.days, 21)
        assertDate(r.deadline, 2026, 10, 10, "CO send deadline")
        assertDate(r.bestSendBy, 2026, 10, 5, "CO best send-by")
    }

    func testCoSixtyDayRentIncrease() throws {
        let r = try resolve("CO", .rentIncrease, context: LeaseContext(increasePercent: 5, increaseEffectiveDate: date(2026, 10, 31)))
        XCTAssertEqual(r.days, 60)
        assertDate(r.deadline, 2026, 9, 1, "CO send deadline")
        assertDate(r.bestSendBy, 2026, 8, 27, "CO best send-by")
    }

    func testWiTwentyEightDayTermination() throws {
        let r = try resolve("WI", .termination, context: LeaseContext(leaseEndDate: date(2026, 5, 31)))
        XCTAssertEqual(r.days, 28)
        assertDate(r.deadline, 2026, 5, 3, "WI send deadline")
        assertDate(r.bestSendBy, 2026, 4, 28, "WI best send-by")
    }

    func testNcSevenDayTermination() throws {
        let r = try resolve("NC", .termination, context: LeaseContext(leaseEndDate: date(2026, 6, 30)))
        XCTAssertEqual(r.days, 7)
        assertDate(r.deadline, 2026, 6, 23, "NC send deadline")
        assertDate(r.bestSendBy, 2026, 6, 18, "NC best send-by")
    }

    func testOrHighIncreaseNinetyDays() throws {
        let r = try resolve("OR", .rentIncrease, context: LeaseContext(increasePercent: 12, increaseEffectiveDate: date(2027, 1, 1)))
        XCTAssertEqual(r.days, 90)
        assertDate(r.deadline, 2026, 10, 3, "OR send deadline")
        assertDate(r.bestSendBy, 2026, 9, 28, "OR best send-by")
    }

    func testMailBufferConstant() {
        XCTAssertEqual(DeadlineCalculator.mailBufferDays, 5)
    }

    func testBestSendByNeverLandsOnNonBusinessDay() {
        let samples: [(Date, Int)] = [
            (date(2026, 1, 1), 30), (date(2026, 2, 14), 21), (date(2026, 7, 4), 45),
            (date(2026, 11, 26), 30), (date(2026, 12, 25), 60), (date(2027, 1, 1), 90)
        ]
        for (deadline, _) in samples {
            let sendBy = DeadlineCalculator.bestSendBy(from: deadline)
            XCTAssertTrue(HolidayCalendar.isBusinessDay(sendBy), "best send-by \(sendBy) must be a business day")
        }
    }

    func testTxCapIsNone() throws {
        let cap = store.jurisdiction(for: "TX")?.primaryRule(for: .depositCap)
        XCTAssertEqual(cap?.capMonths, nil, "TX has no statutory cap")
    }

    func testAzCapOnePointFiveMonths() throws {
        let cap = try XCTUnwrap(store.jurisdiction(for: "AZ")?.primaryRule(for: .depositCap))
        XCTAssertEqual(cap.capMonths, 1.5)
    }

    func testNyCapOneMonth() throws {
        let cap = try XCTUnwrap(store.jurisdiction(for: "NY")?.primaryRule(for: .depositCap))
        XCTAssertEqual(cap.capMonths, 1.0)
    }

    func testTxCapRuleSkipsDeadline() {
        XCTAssertNil(RuleStore.resolveDays(for: store.jurisdiction(for: "TX")!.primaryRule(for: .depositCap)!, context: LeaseContext()))
    }

    func testTxPenaltyText() throws {
        let entry = try XCTUnwrap(store.jurisdiction(for: "TX")?.primaryRule(for: .depositReturn))
        let text = entry.penalty.penaltyText
        XCTAssertTrue(text.contains("3×"), "TX penalty must state 3x multiplier")
        XCTAssertTrue(text.contains("$100"), "TX penalty must state $100 fixed")
        XCTAssertTrue(text.contains("§92.109"), "TX penalty must cite statute")
    }

    func testEveryDepositRuleCarriesSourceAndVerification() {
        for jurisdiction in store.document.jurisdictions {
            for category in RuleCategory.allCases {
                for entry in jurisdiction.rules(for: category) {
                    XCTAssertTrue(entry.sourceURL.hasPrefix("http"), "\(entry.id) missing source_url")
                    XCTAssertTrue(entry.verifiedDate.hasPrefix("2026"), "\(entry.id) missing 2026 verified_date")
                }
            }
        }
    }

    func testStatusMachineForwardOnly() {
        let deadline = DeadlineInstance(
            ruleID: "T-1", category: .depositReturn, eventDate: date(2026, 1, 1),
            statutoryDeadline: date(2026, 1, 31), bestSendBy: date(2026, 1, 26),
            penaltyText: "test", sourceURL: "https://example.com", verifiedDate: date(2026, 6, 9), resolvedDays: 30
        )
        deadline.recomputeStatus(now: date(2026, 1, 1))
        XCTAssertEqual(deadline.status, .upcoming)
        deadline.recomputeStatus(now: date(2026, 1, 27))
        XCTAssertEqual(deadline.status, .actionNeeded)
        deadline.status = .served
        deadline.recomputeStatus(now: date(2026, 3, 1))
        XCTAssertEqual(deadline.status, .served, "served must never regress")
    }

    func testResolveDaysAppliesConditionTiers() {
        let ca = store.jurisdiction(for: "CA")!.primaryRule(for: .rentIncrease)!
        XCTAssertEqual(RuleStore.resolveDays(for: ca, context: LeaseContext(increasePercent: 5)), 30)
        XCTAssertEqual(RuleStore.resolveDays(for: ca, context: LeaseContext(increasePercent: 12)), 90)
    }
}
