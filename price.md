# Pricing Configuration

## Monetization Model: Subscription (IAP) + Lifetime Non-Consumable

Free download with a functional free tier (1 property + full 50-state rules library). Pro unlocks unlimited usage via auto-renewable subscription (monthly/annual) OR a one-time lifetime purchase — both coexist in StoreKit 2. Zero server costs make the lifetime tier sustainable.

## Subscription Group
- **Group Name**: ServeRight Pro
- **Reference Name**: ServeRight Pro
- **Products in group**: Monthly, Annual (auto-renewable ONLY)

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: ServeRight Pro Monthly
- **Product ID**: `com.zzoutuo.ServeRight.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $6.99 USD per month
- **Display Name**: `ServeRight Pro Monthly` (21 chars, ≤35 ✅)
- **Description**: `Unlimited properties, letters, widgets, calendar` (49 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: ServeRight Pro
- **Restore Purchases**: ✅ Required

### 2. Annual Subscription
- **Reference Name**: ServeRight Pro Annual
- **Product ID**: `com.zzoutuo.ServeRight.pro.annual`
- **Type**: Auto-renewable subscription
- **Price**: $29.99 USD per year (57% savings vs monthly)
- **Display Name**: `ServeRight Pro Annual` (21 chars, ≤35 ✅)
- **Description**: `Unlimited properties, letters, widgets, calendar` (49 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: ServeRight Pro (same group as monthly)
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. Pro Lifetime
- **Reference Name**: ServeRight Pro Lifetime
- **Product ID**: `com.zzoutuo.ServeRight.pro.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $69.99 USD (one-time)
- **Display Name**: `ServeRight Pro Lifetime` (23 chars, ≤35 ✅)
- **Description**: `Pay once, own forever. No subscription needed` (45 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Note**: Zero ongoing costs (no API, no server, local notifications only) — lifetime is sustainable
- **Differentiation Note**: Lifetime unlocks the SAME Pro feature set as the subscription, permanently, for users who dislike recurring charges. Annual ($29.99/yr = $2.50/mo) is the cheapest entry for long-term users; Lifetime pays for itself after ~2.3 years.

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 1 property with unlimited leases and deadline tracking
  - Full 50-state (+DC) rules library: rent-increase notice, deposit return, deposit caps, termination notice — with statute citations
  - Deadline engine with best-send-by back-computation (+5-day mail buffer)
  - Local push reminders T-14/7/3/1 days
  - Penalty risk dashboard
  - 1 compliance letter PDF per month
  - Lock screen / home widget for the nearest 1 deadline
  - Manual rule overrides
- **Conversion hooks**:
  - "You've reached the free limit of 1 property. Go Pro for unlimited."
  - "Free letter used this month. Go Pro for unlimited letters."
  - "Track every deadline on your Lock Screen — Pro shows all of them."

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (All Paid Tiers) |
|---------|:----:|:--------------------:|
| Properties / leases | 1 property | Unlimited |
| 50-state rules library | ✅ Full | ✅ Full |
| Deadline engine + reminders | ✅ | ✅ |
| Penalty risk dashboard | ✅ | ✅ |
| Compliance letters (PDF) | 1 / month | Unlimited |
| Widget deadlines shown | Nearest 1 | All deadlines |
| Annual compliance calendar | ❌ | ✅ |
| Manual rule overrides | ✅ | ✅ |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription; 1 per user)
- **Available for**: Annual subscription (default-selected tier); Lifetime purchase also offers the 7-day trial via promotional offer config in App Store Connect

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView
- [x] Free trial terms included
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
