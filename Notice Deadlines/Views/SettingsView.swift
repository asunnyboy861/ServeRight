import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    @AppStorage("icloud_sync_enabled") private var icloudSyncEnabled = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pro") {
                    if purchaseManager.isPro {
                        Label("ServeRight Pro active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.accentColor)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade to Pro", systemImage: "lock.open.fill")
                        }
                    }
                    Button {
                        Task { await purchaseManager.restorePurchases() }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }

                Section {
                    Toggle("iCloud Sync (optional)", isOn: $icloudSyncEnabled)
                } footer: {
                    Text(icloudSyncExplanation)
                }

                Section("Notifications") {
                    LabeledRow(label: "Reminders", value: "14 / 7 / 3 / 1 days before best send-by")
                    LabeledRow(label: "Delivery", value: "Local device notifications")
                }

                Section("Data") {
                    LabeledRow(label: "Storage", value: "On this device only")
                    LabeledRow(label: "Accounts", value: "None required")
                    LabeledRow(label: "Rules version", value: RuleStore.shared.version)
                }

                Section("Legal") {
                    Link(destination: URL(string: "https://asunnyboy861.github.io/ServeRight/privacy.html")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://asunnyboy861.github.io/ServeRight/terms.html")!) {
                        Label("Terms of Use", systemImage: "doc.text.fill")
                    }
                    Link(destination: URL(string: "https://asunnyboy861.github.io/ServeRight/support.html")!) {
                        Label("Support", systemImage: "questionmark.circle.fill")
                    }
                    NavigationLink {
                        ContactSupportView()
                    } label: {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                }

                Section {
                    Text("ServeRight provides legal information, not legal advice. State law changes over time — verify every rule with the linked official statute before acting.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text(appVersion)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var icloudSyncExplanation: String {
        if FileManager.default.ubiquityIdentityToken == nil {
            return "iCloud is not signed in on this device. The app works fully with local storage; sync requires an iCloud account."
        }
        return "When enabled, your data syncs through your private iCloud database. No third-party servers are involved. Takes effect on next app launch."
    }
}
