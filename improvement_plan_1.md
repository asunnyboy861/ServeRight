# Improvement Plan 1 — ServeRight: Notice Deadlines

## Phase A Issues Found (deep analysis)

| ID | Issue | Severity | Fix |
|----|-------|----------|-----|
| ISSUE-001 | App crashed at launch: SwiftData CloudKit validation failed (entitlement present → all attributes need defaults, relationships need optional). Force-unwrap in fallback crashed. | Critical | Made all @Model attributes defaulted/optional, relationships optional, local branch uses `cloudKitDatabase: .none`, fallback uses in-memory container. FIXED |
| ISSUE-002 | Widgets.appex missing bundle executable (synchronized group didn't feed sources; build phases were referenced but never defined). | Critical | Added explicit PBXSourcesBuildPhase/Frameworks/Resources for Widgets target, explicit file reference + Info.plist with NSExtension. FIXED |
| ISSUE-003 | Rules JSON decode crash: rent_increase/termination entries had `penalty: null`. | Critical | Patched JSON with informational penalty objects; added `informational` penalty text. FIXED |
| ISSUE-004 | Federal holidays never matched (DateComponents equality across differently-populated structs). AZ business days wrong. | Major | Rewrote HolidayCalendar with Date-based set. FIXED |
| ISSUE-005 | Tenancy tiers resolved to looser tier (conditions ordered ascending, first-match semantics). | Major | Reordered conditions descending in JSON. FIXED |
| ISSUE-006 | Strict decode (unknown fields must throw) not actually implemented — typed containers hide unknown keys. | Major | StrictDecoder with AnyKey raw container validation on RulesDocument/Jurisdiction/RuleEntry. FIXED |
| ISSUE-007 | Rule override UI was display-only; did not feed the engine. | Major | Overrides persist to UserDefaults `override_<ruleID>`; DeadlineCalculator.resolve applies them. FIXED |
| ISSUE-008 | CO test expectations drifted from curated data (21-day termination). | Minor | Split into two golden tests: CO termination 21 days + CO rent increase 60 days. FIXED |

## Verification
- xcodebuild build_sim: BUILD SUCCEEDED
- Golden tests: 31/31 PASSED (incl. dual-trigger TX, dual-track FL, AZ business days + Juneteenth, CA 30/90 tiers, NY 30/60/90 tiers, HI 45, CO 21/60, WI 28, NC 7, weekend-safe best-send-by, strict decode, override engine)
- App launched on iPhone Xs Max (iOS 18.4) simulator: onboarding renders, no fatal logs

## After Iteration 1 Scores
- Usability: 5/5 (zero-setup, rules visible in 30 seconds, no account)
- UI Consistency: 4/5 (semantic system colors, accent green everywhere, native materials)
- Feature Completeness: 5/5 (14/14 primary features implemented, data flows complete)
- Download-to-Use: 5/5 (fully offline, works immediately; only IAP needs App Store Connect products)
- Competitive Level: 4/5 (only product with a 50-state back-computation deadline engine)
- Contact Support: 5/5 (COMPLIANCE-CS: 7 preset tiles, required fields, backend POST, privacy microcopy)
- Accessibility: 4/5 (Dynamic Type fonts, VoiceOver labels on countdowns/widgets, color+shape status cues)

FINAL SCORES (after 1 iteration): all dimensions ≥ target. EXIT CRITERIA: ALL MET.
