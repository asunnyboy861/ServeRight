# ServeRight: Notice Deadlines — iOS Development Guide

> **App Store Name**: ServeRight: Notice Deadlines (28 chars)
> **Subtitle**: 50-State Landlord Deadlines (25 chars)
> **Tagline**: "Serve every notice right. Every state. On time."
> **Bundle ID**: `com.zzoutuo.ServeRight`
> **Minimum iOS**: 17.0
> **Category**: Business | **Age Rating**: 4+

---

## Executive Summary

ServeRight is a **fully offline, local-first, no-account** iOS app for U.S. "mom-and-pop" landlords who own 1–10 rental units and self-manage without a property manager (~11 million people in the US market).

**The Problem**: All 50 states set different statutory notice deadlines — rent-increase notice periods, security-deposit return windows, deposit caps, and lease-termination notice periods — and these laws change almost every year. Landlords who miss a statutory deadline face hard legal cliffs: a rent increase becomes void (loses a month of rent), or a late deposit return triggers **2×–3× punitive damages plus attorney fees** (about 22 states).

**The Solution**: A built-in 50-state rules database (JSON) → the user enters a lease → the rule engine automatically back-computes every statutory deadline and the **best send-by date** (with a +5-day certified-mail buffer) → system-level push reminders → one-tap generation of a compliance letter PDF citing the state statute.

**Key Differentiators**:
1. **The only product** doing a "statutory notice deadline back-computation engine" for all 50 US states (verified via GitHub + App Store research 2026-09: zero open-source equivalents; competitors like TurboTenant treat notices as a side feature).
2. **Zero server, zero API cost, no account** — the anti-subscription-fatigue weapon. Lifetime purchase is sustainable because there is no recurring cloud cost.
3. **Moat**: 50 states × 4 rule categories ≈ 200+ hand-curated rule entries with five-tuple data model (trigger + days + calendar type + conditions + penalty), which competitors cannot replicate in a week.
4. **Privacy as a weapon**: App Privacy label "Data Not Collected" — contrast with TurboTenant/Avail data collection.

---

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| TurboTenant | Full-suite web+app, free tier, big brand | Essentials $149/yr; notice reminders are an afterthought; no state-law deadline engine; collects user data | $29.99/yr = 1/5 the price; dedicated deadline engine; zero data collection |
| RentRedi | $144/yr unlimited units, mobile-first | Full-suite weight casual landlords don't want; no statutory back-computation | Single-purpose "light" tool; on-device only; Lifetime $69.99 |
| Prorate Calculator Pro | 50-state guidance on late fees/deposits/rent-increase caps; calculator suite | No deadline back-computation, no serve-by countdown, no letter generator with statute citations | We compute the actual dates and remind; they just show reference tables |
| Eviction Helper | 50-state eviction notice rules + certified-mail flow | Eviction-focused only (sensitive term); no deposit/rent-increase coverage; no deadline radar | Covers all 4 notice categories; avoids "eviction" wording on first screen |
| Rental Tracker — Landlord | Offline-first, free 1 property + Pro subscription — validated model | Rent ledger focus; deposit is just a note field; no state rules | Rules library free for all (ASO content moat); deadline engine is the product |
| Rent Guard Dubai | Same product shape (Notice Checker + Letters + Protection Score) validated in small market | Dubai only, 90-day single rule; no US version | US 50-state coverage with dual-trigger/dual-track rule fidelity |

**Pricing anchors** (verified 2026-07): TurboTenant Essentials $149/yr (1–10 units), RentRedi $144/yr, Landlord Studio $12/mo, Landlordy $14.99 one-time. A lawyer drafting one rent-increase notice costs $150–500.

---

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | 50-State Rules Library | Tab "Rules" → pick state → pick category (Rent Increase / Deposit Return / Deposit Cap / Termination) → view rule card | State selection, category selection | Load JSON rule for (state, category); resolve conditions | Rule card: days, calendar type, conditions, penalty text, statute citation as tappable link, version + verified date | None (read-only from bundle JSON) | All 50 states + DC present for 4 categories; verified_date + source_url visible and tappable; fully available offline |
| 2 | Property / Lease Cards | "Properties" tab → + → enter nickname, street, state → enter lease details (tenant, rent, deposit, start/end dates, tenancy years) → save | Nickname, street, state code, tenant name, monthly rent, deposit amount, lease start, lease end (nil = month-to-month), tenancy years | Validation (state code valid, deposit ≥ 0, end > start); triggers full deadline rebuild (idempotent) | Property card list; lease detail view | SwiftData `Property` / `Lease` models | Free tier limited to 1 property (Pro unlimited); editing any lease field rebuilds deadlines atomically |
| 3 | Deadline Radar (Home) | App open → first screen shows the single most urgent deadline as a giant countdown number (96pt SF Pro Rounded) with green/amber/red status | None (derived) | Query all DeadlineInstances, sort by bestSendBy, compute days remaining, status: upcoming (green) / action_needed (amber) / deadline-day-or-passed (red) | Giant countdown card + risk amount; secondary list of all deadlines grouped by status | Derived from SwiftData | First screen = the answer ("What's my next legal action? How many days?"); 0 paywall clicks before first rule card seen |
| 4 | Deadline Engine + Back-computation | Automatic after lease save/edit | Lease events: lease start/end, rent-increase intent (%), keys returned date, forwarding address received date | RuleEngine resolves five-tuple rule for state; DeadlineCalculator computes statutoryDeadline (calendar or business days) and bestSendBy (deadline − notice days − 5-day mail buffer, weekends skipped); Scheduler state machine: upcoming → action_needed → served → compliant/expired | DeadlineInstance records with ruleID, category, statutoryDeadline, bestSendBy, penaltyText, status, sourceURL, verifiedDate | SwiftData `DeadlineInstance` | Golden tests ≥20 pass (TX dual-trigger, FL dual-track, AZ business days, CA 30/90 increase tiers, NY 30/60/90 tenancy tiers, HI 45 days, CO 60 days); any lease edit → full delete-and-rebuild of its deadlines (idempotent, no incremental patching) |
| 5 | Local Push Reminders | Automatic after deadline creation; notification permission requested AFTER first countdown card is seen | Permission grant | Schedule T-14 / T-7 / T-3 / T-1 day local notifications at bestSendBy using UNCalendarNotificationTrigger (absolute date, tamper-resistant); on launch, recompute & reschedule all (full recompute fallback) | System notifications: "2 weeks left / 1 week left / 3 days left / TOMORROW" with penalty text | UNUserNotificationCenter scheduled requests | Kill app, reboot, change system date ±1 day → notifications still fire at correct absolute dates |
| 6 | Compliance Letter Generator (Notice Wizard) | From amber/red card → "Generate Notice" → 4-step wizard: (1) confirm recipient + effective date → (2) choose letter type (rent increase / deposit itemized return / non-renewal) with auto-matched statute citation → (3) choose delivery method incl. USPS Certified Mail checklist → (4) export PDF / print / mark as served | Tenant name, property address, new rent, effective date, delivery method, deposit deduction line items (for itemized letter) | Template engine fills placeholders ({{tenant}}, {{address}}, {{state_code}}, {{statute}}, {{new_rent}}, {{effective_date}}); PDFKit renders US Letter (612×792pt) with disclaimer as first line; timestamp archived | PDF (share/print), letter archive entry with timestamp, deadline status → served → compliant; compliance streak +1 with spring animation + haptic | SwiftData letter archive; PDF via ShareSheet/Files | From amber warning to PDF in hand ≤ 4 taps / 60 seconds; every PDF's first line = "Legal information, not legal advice."; statute citation with link included |
| 7 | Penalty Risk Dashboard | Shown on Home card and deadline detail ("If you miss this week = up to $X") | Derived from rule penalty object | Compute worst-case penalty amount: fixed + multiplier × deposit + attorney fees (e.g., TX §92.109: $100 + 3× deductions + fees ≈ up to $6,100) | Red monospaced dollar amount on risk card | Derived | Penalty text uses concrete dollar figures, not vague "may be liable"; matches statute citation |
| 8 | Onboarding (3 Questions) | First launch → Q1: which state is your property in? → Q2: how many properties (1 / 2–5 / 6+)? → Q3: biggest concern (rent increase / deposit / non-renewal)? → Magic Moment | State code, property count, concern category | Immediately show that state's rule card + risk dashboard — no signup, no purchase | State rule card + pre-filtered dashboard | State preference stored (UserDefaults) | New user sees their state's rule card ≤ 30 seconds from launch, 0 paywall interactions |
| 9 | StoreKit 2 Paywall | Settings or when hitting free-tier limit → Paywall | Product selection | StoreKit 2: Pro Monthly $6.99, Pro Annual $29.99 (default selected, 7-day free trial), Pro Lifetime $69.99 non-consumable; restore purchases | Entitlement state gates: property count (1 vs ∞), letters per month (1 vs ∞), widget deadline count (1 vs all), annual calendar | StoreKit 2 Transaction/entitlements; local receipt state | Subscription + lifetime coexist; 7-day trial on annual; restore works; paywall contains Privacy Policy + Terms links, price, length, auto-renew disclosure |
| 10 | Lock Screen Widget + Dynamic Island | User adds widget; Live Activity auto-activates when nearest deadline ≤ 3 days | Widget extension reads shared app group data | Lock screen accessoryCircular shows days remaining; Home widget shows next deadline; Dynamic Island countdown when ≤ 3 days | System widget / Live Activity | App Group shared UserDefaults/SwiftData snapshot | Free: nearest 1 deadline; Pro: all deadlines; updates without opening app |
| 11 | Manual Rule Override | Rule card → "Override" → enter custom days (e.g., stricter city ordinance) → save with mandatory source label | Custom days + optional note | DeadlineInstance marked isUserOverridden; UI badge "User-defined, not state default" | Overridden deadline used in computation; badge shown everywhere | SwiftData flag | Overrides always visibly labeled; can revert to state default |
| 12 | Annual Compliance Calendar (Pro) | "Calendar" tab → 12-month view of all deadlines per unit | Derived | Lay out all DeadlineInstances on calendar by month | Month grid with colored deadline dots; tap → deadline detail | Derived | Pro only; free tier shows upsell |
| 13 | iCloud Sync (optional) | Settings → Enable iCloud Sync | iCloud account | SwiftData CloudKit private-database sync (no custom server) | Data on all user devices | CloudKit private DB | Off by default; on = seamless sync; no data reaches any third-party server |
| 14 | Settings & About | Settings tab → notifications settings, iCloud toggle, Pro status/restore, About (version via Bundle.main), legal links | User preferences | Read dynamic version from Info.plist; deep-link policy pages | Settings UI | UserDefaults | Version never hardcoded; legal links present; feedback/contact email accessible |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 1.1 | Rules Library | Statute link tap | Opens source_url in SFSafariView / browser | Tap |
| 1.2 | Rules Library | Rule version footer | "This rule last verified 2026-06-09 · v2026.1" | Passive display |
| 2.1 | Properties | State picker | Searchable 50-states + DC picker with flag-less US state names | Picker sheet |
| 2.2 | Properties | Month-to-month toggle | Lease end date optional (nil = month-to-month) | Toggle reveals/hides DatePicker |
| 4.1 | Deadline Engine | Lease event inputs | Rent-increase intent (% + effective date), keys-returned date, forwarding-address-received date drive category-specific triggers | Lease edit form fields |
| 4.2 | Deadline Engine | Business-day calendar | AZ etc. count business days; skip weekends + federal holidays (holiday table in bundle JSON) | Automatic |
| 6.1 | Notice Wizard | USPS Certified Mail checklist | Step 3 shows checklist card: prepare letter, PS Form 3800, photograph receipt number field, keep green card | Checklist UI |
| 6.2 | Notice Wizard | Mark as served | Sets servedOn = today, status → served; later auto → compliant when deadline passes | Button + date confirm |
| 6.3 | Notice Wizard | Compliance streak | Green checkmark spring animation + "Compliant streak: N" counter | Celebration animation + haptic .success |
| 8.1 | Onboarding | Notification permission timing | Permission requested only after the first countdown card is displayed | System alert (delayed) |
| 9.1 | Paywall | Trial conversion | 7-day trial auto-granted on annual/lifetime selection | StoreKit 2 offer |
| 11.1 | Rule Override | Revert to default | One-tap revert removes override and recomputes | Swipe/button |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Lease saved → deadlines rebuilt | Property/Lease (2) | Deadline Engine (4) | Lease event dates + property state | On lease create/edit (full idempotent rebuild) |
| Deadlines → reminders | Deadline Engine (4) | Notifications (5) | DeadlineInstance (bestSendBy, ruleID, penaltyText) | On rebuild / app launch |
| Deadlines → Radar | Deadline Engine (4) | Deadline Radar (3) | Sorted instances with status | View appear + foreground |
| Amber/red card → Wizard | Radar (3) | Letter Generator (6) | deadlineID context | Tap "Generate Notice" |
| Letter served → status | Letter Generator (6) | Engine state machine (4) | servedOn date | Wizard step 4 |
| Entitlement → limits | Paywall (9) | Properties (2), Letters (6), Widgets (10), Calendar (12) | isPro flag | On transaction / launch |
| Rule override → engine | Rule Override (11) | Engine (4) | custom days | On override save/revert |
| App data → widget | All (10) | Widget extension | App Group snapshot (next deadlines) | On data change + timeline refresh |

**VERIFICATION CHECK**: 14 primary features + 11 sub-features enumerated — matches every feature in the Chinese guide (§3.2 MVP table P0×3, P1×2, P2×2, P3×1, plus onboarding, Radar, Wizard, notifications, StoreKit, streak, versioning, iCloud, settings). ✅

---

## Apple Design Guidelines Compliance

- **Native materials**: iOS 26 Liquid Glass-compatible native materials; zero custom skeuomorphism. (US users rate non-native apps lower.)
- **First screen = the answer**: one question, one answer. Single 96pt SF Pro Rounded countdown number; everything else secondary.
- **Color semantics**: green = Compliant, amber = Action Window Open, red = Deadline Day/Passed; penalty amounts in red monospaced digit variant.
- **Dynamic Type**: full support; VoiceOver reads "12 days remaining, action window open".
- **No loading spinners**: everything is local — the absence of loading is itself a delight.
- **US conventions**: US Letter paper (612×792pt), mm/dd/yyyy, USD, sqft. Never metric/A4.
- **Sensitive wording**: avoid "eviction" on first screen (use "notice") to reduce sensitive-category risk.
- **Haptics**: `.success` on compliance completion; spring animations only.
- **Accessibility**: all countdowns expose semantic labels; minimum tap targets 44pt.

---

## Technical Architecture

- **Language**: Swift 6 (strict concurrency where practical), SwiftUI + NavigationStack
- **Persistence**: SwiftData (iOS 17+) with optional CloudKit private-DB sync (no custom server)
- **Notifications**: UserNotifications + `UNCalendarNotificationTrigger` (absolute dates, tamper-resistant); full reschedule on launch
- **PDF**: PDFKit + `UIGraphicsPDFRenderer` (US Letter 612×792)
- **Rules data**: App-bundle JSON (Codable) with semantic version `2026.1`; unknown fields must `throw` on decode (fail loudly, no silent errors)
- **Payments**: StoreKit 2 (auto-renewable subscription + non-consumable lifetime, 7-day trial)
- **Widgets**: WidgetKit lock-screen accessoryCircular + Home widget + ActivityKit Dynamic Island (≤ 3 days)
- **Dependencies**: ZERO third-party packages. Only system frameworks. (Privacy + offline are selling points.)

---

## Module Structure

```
Notice Deadlines/                    (Xcode project, SwiftUI app lifecycle)
├── ServeRightApp.swift              (App entry, SwiftData container, launch recompute)
├── Models/
│   ├── Property.swift               (@Model)
│   ├── Lease.swift                  (@Model)
│   ├── DeadlineInstance.swift       (@Model, state machine)
│   └── LetterArchive.swift          (@Model, PDF timestamp chain)
├── Rules/
│   ├── RuleModels.swift             (StateRule, RuleEntry five-tuple, Penalty — strict Codable)
│   ├── RuleStore.swift              (JSON load, lookup by state+category, version)
│   └── Resources/Rules/rules_2026_1.json   (50 states + DC × 4 categories)
├── Engine/
│   ├── DeadlineCalculator.swift     (statutoryDeadline, bestSendBy, business days, mail buffer)
│   ├── RuleEngine.swift             (lease events → DeadlineInstances, idempotent rebuild)
│   └── HolidayCalendar.swift        (US federal holidays JSON)
├── Services/
│   ├── NotificationScheduler.swift  (T-14/7/3/1 absolute-date triggers, full reschedule)
│   ├── LetterRenderer.swift         (template placeholders → PDF via UIGraphicsPDFRenderer)
│   ├── StoreService.swift           (StoreKit 2: monthly/annual/lifetime, trial, restore)
│   └── Entitlements.swift           (free limits: 1 property, 1 letter/mo, 1 widget deadline)
├── Views/
│   ├── Onboarding/ (3-question flow + magic moment)
│   ├── Radar/ (home giant countdown + status list + risk card)
│   ├── Properties/ (list, property editor, lease editor)
│   ├── Rules/ (state picker, category tabs, rule card, override sheet)
│   ├── Wizard/ (4-step Notice Wizard, USPS checklist, PDF preview/share)
│   ├── Calendar/ (annual compliance calendar, Pro)
│   ├── Paywall/ (StoreKit 2 + legal links + auto-renew disclosure)
│   └── Settings/ (notifications, iCloud, about, legal)
├── Widgets/ (lock screen + home widget + Live Activity)
└── Tests/
    └── RulesGoldenTests.swift       (≥20 hardcoded golden cases)
```

---

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

```
Feature: Deadline Engine (core)
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Lease form: state, dates, rent, deposit, tenancy     │
│      years, keysReturnedOn, forwardingAddressReceivedOn   │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── LeaseEditorViewModel → validate → RuleEngine         │
│      resolve(state, category) → DeadlineCalculator        │
│      compute statutoryDeadline & bestSendBy               │
│       │                                                   │
│  Model/Persistence                                        │
│  └── SwiftData: delete all Lease.deadlines, recreate      │
│      (idempotent full rebuild) → DeadlineInstance rows    │
│       │                                                   │
│  Display Output                                           │
│  └── Radar: sort by bestSendBy → giant countdown + color  │
│       │                                                   │
│  Cross-Feature Output                                     │
│  └── NotificationScheduler (4 absolute-date triggers)     │
│  └── Widget snapshot via App Group                        │
│  └── Risk Dashboard (penalty worst-case $)                │
└───────────────────────────────────────────────────────────┘

Feature: Notice Wizard → PDF
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── 4 steps: recipient/effective date → letter type →    │
│      delivery method (+USPS checklist) → export/serve     │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── WizardViewModel → pick template by category →        │
│      fill placeholders (tenant, address, statute, rent…)  │
│       │                                                   │
│  Model/Persistence                                        │
│  └── LetterArchive row (timestamp = evidence chain) +     │
│      DeadlineInstance.servedOn; status → served           │
│       │                                                   │
│  Display Output                                           │
│  └── PDFKit-rendered US Letter PDF w/ disclaimer line 1;  │
│      ShareSheet (save/print); streak celebration          │
└───────────────────────────────────────────────────────────┘

Feature: Rules Library
┌───────────────────────────────────────────────────────────┐
│  User Input: state picker + category tabs                 │
│  ViewModel: RuleStore.load(stateCode, category)           │
│  Model: bundle JSON rules_2026_1.json (strict decode)     │
│  Display: rule card w/ days, calendar type, conditions,   │
│  penalty, statute link, version + verified date footer    │
│  Cross: "Override" → writes user override → Engine        │
└───────────────────────────────────────────────────────────┘

Feature: StoreKit 2 Entitlements
┌───────────────────────────────────────────────────────────┐
│  User Input: paywall product tap / restore                │
│  ViewModel: StoreService.purchase() → Transaction.verify  │
│  Model: Entitlements (isPro) → UserDefaults + App Group   │
│  Display: gates update live (property count, letters,     │
│  widgets, calendar)                                       │
└───────────────────────────────────────────────────────────┘
```

**VERIFICATION CHECK**: every primary feature has a traceable input → processing → persistence → display path. ✅

---

## Implementation Flow

1. **Rules data pipeline**: author `rules_2026_1.json` — 50 states + DC × 4 categories (rent_increase, deposit_return, deposit_cap, termination), each rule entry with `id`, `trigger`, `days`, `calendar`, `conditions`, `penalty`, `source_url`, `verified_date`. Strict Codable — unknown fields throw.
2. **Models**: SwiftData `Property`, `Lease`, `DeadlineInstance`, `LetterArchive`.
3. **Engine**: `DeadlineCalculator` (startOfDay everywhere; calendar vs business days; 5-day mail buffer; weekend skip) + `RuleEngine` idempotent full rebuild.
4. **Notifications**: absolute-date triggers T-14/7/3/1 at bestSendBy; full reschedule on every launch.
5. **Golden tests**: ≥20 hardcoded cases (TX dual trigger, FL dual track, AZ business days, CA 30/90 tiers, NY 30/60/90 tiers, HI 45, CO 60…). All engine changes must pass.
6. **UI**: Onboarding 3 questions → Radar → Properties → Rules → Wizard → Paywall → Settings → Calendar.
7. **Letters**: 3 templates (rent increase / deposit itemized return / non-renewal) with statute citations + PDF renderer.
8. **StoreKit 2**: monthly/annual(trial)/lifetime + restore.
9. **Widgets**: lock screen + home + Dynamic Island via App Group.
10. **Polish**: streak animation, haptics, Dynamic Type, disclaimers everywhere.

---

## UI/UX Design Specifications

- **Home (Deadline Radar)**: giant countdown (SF Pro Rounded 96pt), status color, risk amount card ("If you miss this week: up to $6,100"), "Generate Notice" primary button on amber/red.
- **Palette**: system semantic colors (green/amber/red) + system backgrounds; penalty text `.monospacedDigit()` red.
- **Copy tone**: direct, short, number-first. "You have 12 days to serve this notice." Never "Please be advised…".
- **Reassurance moment**: after setup, explicitly tell the user "You can close me now — I'll remind you 14 days before."
- **Celebration**: green checkmark spring + haptic .success + "Compliant streak: N".
- **Disclaimers**: fixed footer in app + first line of every PDF: "Legal information, not legal advice. Verify with your state statute."
- **Empty/loading states**: none needed (fully local).

---

## Code Generation Rules

- Rules data and code are strictly separated: all rules in JSON; changing a rule NEVER touches Swift code.
- All dates computed with `startOfDay` in the user's local calendar; display in user's local time zone.
- State machine only moves forward: served/compliant never auto-regress.
- Idempotent full rebuild of deadlines on any lease change — no incremental patching.
- Every rule UI shows verified_date + source_url (tappable).
- Zero third-party dependencies; no network SDKs; no analytics; no account.
- Version read dynamically from `Bundle.main.infoDictionary` — never hardcoded.
- No AI features. No free-generation counters. No dead code.

---

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
The Paywall MUST contain:
- Functional link to Privacy Policy
- Functional link to Terms of Use (EULA)
- Product title, length, and price for each tier ($6.99/mo, $29.99/yr with 7-day trial, $69.99 lifetime)
- Auto-renewal disclosure text

### Guideline 2.1 — App Completeness
- Fully functional offline (except StoreKit). Reviewers can test everything without accounts or servers.
- Free tier (1 property + full rules library + 1 letter/month) is fully usable without purchase.

### UPL (Unauthorized Practice of Law) Protection
- The app only: displays verified statutory facts with source links, mechanically fills templates from user input, computes dates.
- Every screen footer and PDF first line: "Legal information, not legal advice."
- No "you should…" advice phrasing anywhere.
- App Privacy label: **Data Not Collected** (all green).

---

## Build & Deployment Checklist

- [ ] All 50 states + DC present in rules JSON (4 categories each)
- [ ] Golden tests ≥ 20 pass
- [ ] Kill + relaunch + system-date ±1 day: notifications still correct
- [ ] verified_date + source_url visible and tappable on every rule card
- [ ] New user → state rule card in ≤ 30 seconds, 0 paywall clicks
- [ ] Amber warning → PDF in hand ≤ 4 taps / 60 seconds
- [ ] App size < 15 MB, cold start < 400 ms, zero third-party deps
- [ ] Every PDF first line = disclaimer; every letter cites statute with link
- [ ] StoreKit 2: subscription + lifetime, 7-day trial, restore works
- [ ] App Privacy: Data Not Collected
