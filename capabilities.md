# ServeRight: Notice Deadlines — 配置文档

生成时间：2026-09-15

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**，不配置这些项，App 仍可正常使用所有核心功能（50 州规则库、截止日引擎、本地提醒、信函 PDF、小组件全部离线可用）。配置后可获得完整的付费解锁能力与跨设备同步。

### 🔵 IAP StoreKit 配置（必做 — 否则用户无法完成 Pro 购买）

**影响功能**：不创建 IAP 产品则 Paywall 显示"购买选项不可用"，用户无法升级 Pro；免费层不受影响

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → **ServeRight: Notice Deadlines** → **Features**（功能）→ **In-App Purchases**（App 内购买项目）
2. 点击 **"+"** 先创建订阅组 **"ServeRight Pro"**，然后在组内创建 2 个自动续期订阅产品：

| 产品 | Reference Name | Product ID | 价格 | 其他 |
|------|---------------|-----------|------|------|
| 月付 | ServeRight Pro Monthly | `com.zzoutuo.ServeRight.pro.monthly` | $6.99/月 | 无试用 |
| 年付 | ServeRight Pro Annual | `com.zzoutuo.ServeRight.pro.annual` | $29.99/年 | **Introductory Offer 选 7 天免费试用** |

3. 再点击 **"+"** → 选择 **Non-Consumable（非消耗型）** 创建买断产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| 买断 | ServeRight Pro Lifetime | `com.zzoutuo.ServeRight.pro.lifetime` | $69.99（一次性） |

4. 每个产品的 Display Name 和 Description（≤55 字符）从项目根目录 `price.md` 直接复制：
   - Display Name：`ServeRight Pro Monthly` / `ServeRight Pro Annual` / `ServeRight Pro Lifetime`
   - Description：`Unlimited properties, letters, widgets, calendar`（订阅）/ `Pay once, own forever. No subscription needed`（买断）
5. 本地测试：在 Xcode 中 File → New → File → **StoreKit Configuration File**，按上表添加 3 个产品即可在模拟器测试完整购买流程
6. 创建完成后用真机/模拟器走一遍 **购买 → Restore Purchases（设置页与 Paywall 均有入口）** 验证流程
7. ⚠️ 产品创建后需等 Apple 处理（通常 1-2 小时）才能关联到提交审核的版本

### 🟡 Capabilities 增强配置（可选 — iCloud 跨设备同步）

#### iCloud CloudKit 容器注册验证

**增强功能**：开启后用户数据通过其私有 iCloud 库跨设备同步
**不配置的影响**：App 默认纯本地存储，所有功能正常，仅无跨设备同步
**当前状态**：App 已使用本地存储作为默认方案（`cloudKitDatabase: .none`），无需配置即可正常使用

**已自动配置部分**：
- ✅ `ServeRight.entitlements` 已声明 iCloud 容器 `iCloud.com.zzoutuo.ServeRight` + CloudKit 服务
- ✅ 代码已实现优雅降级（未启用时用本地库；用户在 Settings 里打开开关且 iCloud 可用时才走 CloudKit）

**如需启用增强功能，请手动验证**：
1. 打开 [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**
2. 找到 App ID `com.zzoutuo.ServeRight` → 编辑 → 确认 **iCloud**（含 CloudKit）已勾选，容器 `iCloud.com.zzoutuo.ServeRight` 已关联（Xcode 自动签名通常已自动注册；若真机构建报 iCloud 描述文件错误，在此手动勾选即可）
3. [CloudKit Console](https://icloud.developer.apple.com) 确认容器已创建（首次真机构建后自动出现）
4. ⚠️ 配置完成后重新 Build 验证

---

### 🟢 App Store Connect 审核信息配置（提交前）

**影响功能**：不配置不影响功能，但影响审核通过率

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**（App 审核信息）
2. 在 **Notes**（备注）字段粘贴 `keytext.md` 末尾 "Review Notes" 一节的内容（含订阅产品 ID、法律免责声明说明、本地通知说明）
3. 确保 **Privacy Policy URL** 填 `https://asunnyboy861.github.io/ServeRight/privacy.html`
4. 确保版本页面的 **Terms of Use (EULA)** 字段或描述中含 `https://asunnyboy861.github.io/ServeRight/terms.html`（订阅类 App 必须）
5. **Marketing URL / Support URL** 填 `https://asunnyboy861.github.io/ServeRight/support.html`

> 💡 App Store ID 获取后（App Store Connect 创建 App 时分配），替换 `docs/index.html` 中的 `[APP_STORE_ID]` 占位符并推送，Landing Page 的下载按钮即自动变为可用状态。

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| UserNotifications（本地通知） | 系统框架，无需 entitlement；T-14/7/3/1 绝对日期触发 | ✅ 已配置 |
| In-App Purchase (StoreKit 2) | 系统框架，PurchaseManager 已实现 3 产品 + 恢复购买 | ✅ 已配置 |
| App Group `group.com.zzoutuo.ServeRight` | App 与 Widgets 扩展共享数据 | ✅ 已配置 |
| WidgetKit 扩展 target | `Widgets` 扩展（锁屏/主屏倒计时），已嵌入 App | ✅ 已配置 |
| iCloud + CloudKit entitlement | `ServeRight.entitlements` 已声明容器 | ✅ 已配置 |
| PDFKit | 系统框架，US Letter PDF 渲染 | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers：`https://feedback-board.iocompile67692.workers.dev/api/feedback`，已硬编码进 ContactSupportView | ✅ 已部署 |
| 网络权限 | 后端为 HTTPS，iOS 默认放行；无 ATS 例外需求 | ✅ 已配置 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 14/14 功能模块（规则库/引擎/提醒/信函/小组件/日历/覆盖等） | ✅ 已完成 |
| 规则数据 | 51 司法辖区 × 4 类规则 JSON（五元组+条件+罚则+来源链接），严格解码 | ✅ 已完成 |
| Golden Tests | 31 条单元测试（TX 双触发/FL 双轨/AZ 工作日/CA·NY 分档等）全部通过 | ✅ 已完成 |
| ContactSupportView | 7 主题磁贴 + 必填字段 + 后端对接 + 隐私微文案 | ✅ 已完成 |
| SettingsView | 政策页链接、恢复购买、iCloud 开关、动态版本号 | ✅ 已完成 |
| PurchaseManager | StoreKit 2（Transaction.currentEntitlement + 响应式 isPro） | ✅ 已完成 |
| QA 迭代 | 8 项问题修复（含 3 项 Critical），improvement_plan_1.md | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/ServeRight | ✅ 已推送 |
| GitHub Pages | /docs 部署，Landing + Support + Privacy + Terms | ✅ 已启用 |
| Landing Page | 已部署（App Store ID 为占位符，获取后替换） | ✅ 已完成 |
| App Store 元数据 | keytext.md 已生成，15 项验证全部通过 | ✅ 已完成 |
| 定价配置 | price.md 已生成并验证 | ✅ 已完成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据，内容已重组到上方 Section 一、二。

### Analysis

关键词检测：通知/提醒 → UserNotifications（本地，无推送服务器）；订阅/买断/购买 → StoreKit 2；小组件/灵动岛 → WidgetKit + App Group；iCloud 同步 → CloudKit（可选）；纯离线无账号 → 无网络能力、无登录、无分析 SDK。

### No Configuration Needed

- Push Notifications (APNs) — 未使用；提醒全部为 UNCalendarNotificationTrigger 本地通知
- Camera / Location / HealthKit / Siri / Sign in with Apple — 未使用
- 网络 — 零网络 entitlement（仅联系客服 HTTPS 出站，iOS 默认放行）

### Verification

- 配置后构建验证：BUILD SUCCEEDED（iPhone 16 / iOS 26.4、iPad Pro 13-inch M5、iPhone Xs Max / iOS 18.4 三台模拟器实机运行通过）
- Golden Tests：31/31 通过
- Entitlements 校验：App Group + iCloud 声明正确
