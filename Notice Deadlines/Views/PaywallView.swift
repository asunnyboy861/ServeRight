import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var selectedID = PurchaseManager.annualID
    @State private var purchasing = false
    @State private var successMessage: String?

    private static let appSlug = "ServeRight"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)
                    Text("ServeRight Pro")
                        .font(.largeTitle.bold())
                    Text("Never miss a statutory notice deadline again.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 10) {
                        featureRow("house.and.flag", "Unlimited properties & leases")
                        featureRow("doc.badge.plus", "Unlimited compliance letters (PDF)")
                        featureRow("rectangle.and.text.magnifyingglass", "All deadlines on your Lock Screen widget")
                        featureRow("calendar", "Annual compliance calendar")
                        featureRow("clock.badge.checkmark", "Deadline engine + reminders for everything")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    if purchaseManager.products.isEmpty {
                        VStack(spacing: 8) {
                            if purchaseManager.isLoading {
                                ProgressView()
                            } else {
                                Text(purchaseManager.loadError ?? "Purchases are unavailable right now. The free tier remains fully usable.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                    } else {
                        VStack(spacing: 10) {
                            if let annual = purchaseManager.annualProduct {
                                productCard(annual, subtitle: "7-day free trial included", isSelected: selectedID == annual.id)
                            }
                            if let monthly = purchaseManager.monthlyProduct {
                                productCard(monthly, subtitle: "Billed monthly", isSelected: selectedID == monthly.id)
                            }
                            if let lifetime = purchaseManager.lifetimeProduct {
                                productCard(lifetime, subtitle: "Pay once, own forever", isSelected: selectedID == lifetime.id)
                            }
                        }
                    }

                    Button {
                        Task { await purchase() }
                    } label: {
                        if purchasing {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Start Free Trial / Subscribe")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(purchaseManager.products.isEmpty || purchasing)

                    HStack(spacing: 16) {
                        Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/\(Self.appSlug)/privacy.html")!)
                        Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/\(Self.appSlug)/terms.html")!)
                        Link("Support", destination: URL(string: "https://asunnyboy861.github.io/\(Self.appSlug)/support.html")!)
                    }
                    .font(.caption2)

                    Text("Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings. The Lifetime purchase is one-time and never renews.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Restore Purchases") {
                        Task { await purchaseManager.restorePurchases() }
                    }
                    .font(.callout)

                    if let successMessage {
                        Text(successMessage)
                            .font(.callout)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.callout)
        }
    }

    private func productCard(_ product: Product, subtitle: String, isSelected: Bool) -> some View {
        Button {
            selectedID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
    }

    private func purchase() async {
        guard let product = purchaseManager.products.first(where: { $0.id == selectedID }) else { return }
        purchasing = true
        let success = await purchaseManager.purchase(product)
        purchasing = false
        if success {
            successMessage = "You're Pro. Thank you!"
        }
    }
}
