import SwiftUI
import SwiftData

@main
struct Notice_DeadlinesApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Property.self, Lease.self, DeadlineInstance.self, LetterArchive.self])
        do {
            if UserDefaults.standard.bool(forKey: "icloud_sync_enabled"),
               FileManager.default.ubiquityIdentityToken != nil {
                let config = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.zzoutuo.ServeRight"))
                container = try ModelContainer(for: schema, configurations: [config])
            } else {
                container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)])
            }
        } catch {
            print("ServeRight ModelContainer error: \(error)")
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [config])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootGateView()
                .modelContainer(container)
                .task {
                    let context = container.mainContext
                    RuleEngine.rebuildAll(modelContext: context)
                    refreshNotifications(context: context)
                }
        }
    }

    @MainActor
    private func refreshNotifications(context: ModelContext) {
        let descriptor = FetchDescriptor<DeadlineInstance>()
        if let deadlines = try? context.fetch(descriptor) {
            NotificationScheduler.rescheduleAll(deadlines: deadlines)
            WidgetBridge.publishSnapshot(deadlines: deadlines, isPro: PurchaseManager.shared.isPro)
        }
    }
}

struct RootGateView: View {
    @AppStorage("finished_onboarding") private var finishedOnboarding = false

    var body: some View {
        if finishedOnboarding {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}
