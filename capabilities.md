# Capabilities Configuration

## Analysis
Based on operation guide analysis (keywords: 通知/notification/提醒 → UserNotifications; 订阅/买断/购买 → In-App Purchase; 小组件/灵动岛 → WidgetKit + ActivityKit + App Group; iCloud 同步 → iCloud CloudKit; PDF → PDFKit; 纯离线无账号 → no network capability, no sign-in):

- The app is fully offline. No push server — all reminders are LOCAL notifications (no Push Notifications entitlement required).
- Payments are StoreKit 2 (system framework — capability enabled by default, needs App Store Connect products at submission time, not for build).
- Widgets require an App Group to share deadline data between app and extension.
- iCloud is OPTIONAL (graceful degradation: local SwiftData is the default; CloudKit private-DB sync is an enhancement).

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| UserNotifications (local) | ✅ Configured | System framework — no entitlement needed |
| StoreKit 2 (IAP) | ✅ Configured | System framework — enabled by default; product IDs created in App Store Connect before submission |
| WidgetKit extension target | ✅ Configured | `Widgets` app-extension target added to project (bundle `com.zzoutuo.ServeRight.Widgets`, embedded via Embed Foundation Extensions) |
| App Group `group.com.zzoutuo.ServeRight` | ✅ Configured | `ServeRight.entitlements` + `Widgets.entitlements` (auto-registered by Xcode automatic signing, team JP4TN5PTS3) |
| iCloud (CloudKit container `iCloud.com.zzoutuo.ServeRight`) | ✅ Entitlement configured | `ServeRight.entitlements` — code uses local SwiftData by default and enables CloudKit only when the container is available at runtime |
| PDFKit | ✅ Configured | System framework |
| App Group data sharing (app ↔ widget) | ✅ Configured | Shared `UserDefaults(suiteName:)` snapshot |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| App Store Connect IAP products | ⏳ At submission | Create 3 products in App Store Connect: `com.zzoutuo.ServeRight.pro.monthly` ($6.99, auto-renew), `com.zzoutuo.ServeRight.pro.annual` ($29.99, auto-renew, 7-day trial), `com.zzoutuo.ServeRight.pro.lifetime` ($69.99, non-consumable). Not needed for local build/testing. |
| iCloud container registration verification | ⏳ Optional | On first real-device build with signing, Xcode automatically registers `iCloud.com.zzoutuo.ServeRight`. If a device build reports a provisioning error for iCloud, open developer.apple.com → Identifiers → enable iCloud on the App ID. App works fully WITHOUT iCloud (local-only default). |

## No Configuration Needed
- Push Notifications (APNs) — not used; reminders are UNCalendarNotificationTrigger local notifications
- Camera / Location / HealthKit / Siri / Sign in with Apple — not used
- Network — zero network entitlements; app is fully offline

## Project Settings Applied
- Bundle ID: `com.zzoutuo.ServeRight` (Tests: `com.zzoutuo.ServeRightTests`, UITests: `com.zzoutuo.ServeRightUITests`, Widgets: `com.zzoutuo.ServeRight.Widgets`)
- Display name: `ServeRight`
- Deployment target: iOS 17.0 (all targets)
- Development team: JP4TN5PTS3 (automatic signing)
- Widget extension target `Widgets` added and embedded

## Verification
- Build succeeded after configuration: ✅ (verified via simulator build)
- All entitlements correct: ✅
