# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | ServeRight |
| **Git URL** | git@github.com:asunnyboy861/ServeRight.git |
| **Repo URL** | https://github.com/asunnyboy861/ServeRight |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/ServeRight/ | ✅ Active |
| Support | https://asunnyboy861.github.io/ServeRight/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/ServeRight/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/ServeRight/terms.html | ✅ Active |
| App Store Download | https://apps.apple.com/us/app/id6813489678 | ⏳ v1.0 Preparing for Release |

## Repository Structure

```
ServeRight/
├── Notice Deadlines.xcodeproj/    # Xcode Project (App + Widgets + Tests targets)
├── Notice Deadlines/              # iOS App Source Code
│   ├── Notice_DeadlinesApp.swift  # App entry (SwiftData container, launch recompute)
│   ├── ContentView.swift          # Root TabView
│   ├── Models/                    # SwiftData models (Property, Lease, DeadlineInstance, LetterArchive)
│   ├── Rules/                     # Strict-Codable rule engine models + JSON store
│   │   └── Resources/rules_2026_1.json  # 51 jurisdictions × 4 categories
│   ├── Engine/                    # DeadlineCalculator, HolidayCalendar, RuleEngine
│   ├── Services/                  # NotificationScheduler, LetterRenderer, PurchaseManager, WidgetBridge
│   ├── Views/                     # Onboarding, Radar, Properties, Rules, Wizard, Paywall, Calendar, Settings, ContactSupport
│   └── Assets.xcassets/           # AppIcon (1024 universal), AccentColor
├── Widgets/                       # WidgetKit extension (lock screen + home countdown)
├── Notice DeadlinesTests/         # RulesGoldenTests (31 tests)
├── Notice DeadlinesUITests/
├── ServeRight.entitlements        # App Group + iCloud (CloudKit)
├── Widgets.entitlements           # App Group
├── us.md / capabilities.md / icon.md / price.md / improvement_plan_1.md
├── docs/                          # Policy Pages (GitHub Pages source)
├── .github/workflows/deploy.yml
├── .gitignore                     # Protects .env, keytext*.md, COMPETITOR_REPORT.md
├── nowgit.md
├── keytext.md              # ⚠️ EXCLUDED from repo (.gitignore — confidential ASO strategy)
└── COMPETITOR_REPORT.md    # ⚠️ EXCLUDED from repo (.gitignore — confidential competitor analysis)
```
