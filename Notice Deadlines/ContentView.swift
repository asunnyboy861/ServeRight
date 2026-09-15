import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some View {
        TabView {
            RadarView()
                .tabItem { Label("Radar", systemImage: "antenna.radiowaves.left.and.right") }
            PropertiesView()
                .tabItem { Label("Properties", systemImage: "house.fill") }
            RulesView()
                .tabItem { Label("Rules", systemImage: "book.fill") }
            CalendarGateView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color.accentColor)
    }
}

struct CalendarGateView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some View {
        if purchaseManager.isPro {
            CalendarYearView()
        } else {
            ProUpsellView(feature: "Annual Compliance Calendar", detail: "See every deadline for every unit across the whole year. Upgrade to Pro to unlock the 12-month compliance calendar.")
        }
    }
}

struct ProUpsellView: View {
    let feature: String
    let detail: String
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text(feature)
                .font(.title2.bold())
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showPaywall = true
            } label: {
                Text("Upgrade to Pro")
                    .font(.headline)
                    .padding(.horizontal, 32)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
