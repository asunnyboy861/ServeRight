import Foundation
import StoreKit
import Combine

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let monthlyID = "com.zzoutuo.ServeRight.pro.monthly"
    static let annualID = "com.zzoutuo.ServeRight.pro.annual"
    static let lifetimeID = "com.zzoutuo.ServeRight.pro.lifetime"
    static let allIDs = [monthlyID, annualID, lifetimeID]

    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await checkPurchased()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.allIDs)
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkPurchased()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchased()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func checkPurchased() async {
        var entitled = false
        for id in Self.allIDs {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                entitled = true
                break
            }
        }
        if isPro != entitled {
            isPro = entitled
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkPurchased()
                    }
                }
            }
        }
    }

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var annualProduct: Product? { products.first { $0.id == Self.annualID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }
}

enum FreeLimits {
    static let maxFreeProperties = 1
    static let maxFreeLettersPerMonth = 1
    static let maxFreeWidgetDeadlines = 1

    static var lettersUsedThisMonth: Int {
        let key = "letters_used_\(Self.monthKey)"
        return UserDefaults.standard.integer(forKey: key)
    }

    static func recordLetterUsed() {
        let key = "letters_used_\(Self.monthKey)"
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
    }

    static func canWriteLetter(isPro: Bool) -> Bool {
        isPro || lettersUsedThisMonth < maxFreeLettersPerMonth
    }

    private static var monthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: .now)
    }
}
