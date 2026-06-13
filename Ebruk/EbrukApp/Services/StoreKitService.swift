import Foundation
import StoreKit

enum PurchaseResult: Equatable {
    case success(coins: Int)
    case cancelled
    case pending
    case failed(String)
}

@Observable
@MainActor
final class StoreKitService {
    private(set) var productsByID: [String: Product] = [:]
    private(set) var isLoadingProducts = false
    private(set) var isRestoring = false
    private(set) var purchaseHistory: [PurchaseRecord] = []

    private var updateListenerTask: Task<Void, Never>?
    private var deliveredTransactionIDs: Set<UInt64> = []
    private weak var coinStore: CoinStore?

    private let deliveredTransactionsKey = "diy_formula_delivered_transactions"
    private let purchaseHistoryKey = "diy_formula_purchase_history"

    init() {
        if let saved = UserDefaults.standard.array(forKey: deliveredTransactionsKey) as? [UInt64] {
            deliveredTransactionIDs = Set(saved)
        }
        loadPurchaseHistory()
        updateListenerTask = listenForTransactions()
    }

    func attach(coinStore: CoinStore) {
        self.coinStore = coinStore
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        let productIDs = Set(CoinPackage.all.map(\.productID))
        do {
            let products = try await Product.products(for: productIDs)
            productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            if products.isEmpty {
                print("⚠️ [StoreKitService] 未加载到任何商品，请确认 Scheme 已关联 Products.storekit 或 App Store Connect 已配置对应 Product Id")
            } else if products.count < productIDs.count {
                let missing = productIDs.subtracting(products.map(\.id))
                print("⚠️ [StoreKitService] 部分商品未加载: \(missing.sorted().joined(separator: ", "))")
            }
        } catch {
            productsByID = [:]
            print("❌ [StoreKitService] 加载商品失败: \(error.localizedDescription)")
        }
    }

    func displayPrice(for package: CoinPackage) -> String {
        productsByID[package.productID]?.displayPrice ?? package.fallbackPrice
    }

    func purchase(package: CoinPackage) async -> PurchaseResult {
        if productsByID[package.productID] == nil {
            await loadProducts()
        }

        guard let product = productsByID[package.productID] else {
            return .failed("商品暂不可用，请检查网络或稍后重试。")
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                return await handleVerification(verification, package: package)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("未知购买状态，请稍后重试。")
            }
        } catch {
            return .failed("购买失败：\(error.localizedDescription)")
        }
    }

    func restorePurchases() async -> RestoreResult {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
        } catch {
            return .failed("无法连接 App Store：\(error.localizedDescription)")
        }

        var restoredCoins = 0
        var restoredCount = 0

        for await verification in Transaction.unfinished {
            if let delivered = await processVerifiedTransaction(verification, finish: true),
               case .success(let coins) = delivered {
                restoredCoins += coins
                restoredCount += 1
            }
        }

        for await verification in Transaction.currentEntitlements {
            if let delivered = await processVerifiedTransaction(verification, finish: true),
               case .success(let coins) = delivered {
                restoredCoins += coins
                restoredCount += 1
            }
        }

        if restoredCount > 0 {
            return .restored(coins: restoredCoins, count: restoredCount)
        }
        return .nothingToRestore
    }

    func processUnfinishedTransactionsOnLaunch() async {
        for await verification in Transaction.unfinished {
            _ = await processVerifiedTransaction(verification, finish: true)
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                _ = await self.processVerifiedTransaction(update, finish: true)
            }
        }
    }

    @discardableResult
    private func processVerifiedTransaction(
        _ verification: VerificationResult<Transaction>,
        finish: Bool
    ) async -> PurchaseResult? {
        switch verification {
        case .verified(let transaction):
            guard transaction.revocationDate == nil else {
                if finish { await transaction.finish() }
                return nil
            }

            guard let package = CoinPackage.package(for: transaction.productID) else {
                if finish { await transaction.finish() }
                return nil
            }

            let result = await deliverCoinsIfNeeded(for: transaction, package: package)
            if finish { await transaction.finish() }
            return result

        case .unverified:
            return .failed("交易验证失败")
        }
    }

    private func handleVerification(
        _ verification: VerificationResult<Transaction>,
        package: CoinPackage
    ) async -> PurchaseResult {
        switch verification {
        case .verified(let transaction):
            guard transaction.revocationDate == nil else {
                await transaction.finish()
                return .failed("该笔购买已被撤销。")
            }

            let result = await deliverCoinsIfNeeded(for: transaction, package: package)
            await transaction.finish()
            return result
        case .unverified:
            return .failed("购买验证失败，请联系客服。")
        }
    }

    private func deliverCoinsIfNeeded(
        for transaction: Transaction,
        package: CoinPackage
    ) async -> PurchaseResult {
        guard !deliveredTransactionIDs.contains(transaction.id) else {
            return .success(coins: package.coins)
        }

        coinStore?.addCoins(package.coins)
        deliveredTransactionIDs.insert(transaction.id)
        persistDeliveredTransactions()

        let record = PurchaseRecord(
            id: transaction.id,
            productID: transaction.productID,
            coins: package.coins,
            purchasedAt: transaction.purchaseDate,
            environment: transaction.environment.rawValue
        )
        appendPurchaseRecord(record)

        return .success(coins: package.coins)
    }

    private func appendPurchaseRecord(_ record: PurchaseRecord) {
        purchaseHistory.removeAll { $0.id == record.id }
        purchaseHistory.insert(record, at: 0)
        if purchaseHistory.count > 50 {
            purchaseHistory = Array(purchaseHistory.prefix(50))
        }
        savePurchaseHistory()
    }

    private func loadPurchaseHistory() {
        guard let data = UserDefaults.standard.data(forKey: purchaseHistoryKey),
              let decoded = try? JSONDecoder().decode([PurchaseRecord].self, from: data) else {
            purchaseHistory = []
            return
        }
        purchaseHistory = decoded
    }

    private func savePurchaseHistory() {
        guard let data = try? JSONEncoder().encode(purchaseHistory) else { return }
        UserDefaults.standard.set(data, forKey: purchaseHistoryKey)
    }

    private func persistDeliveredTransactions() {
        UserDefaults.standard.set(
            Array(deliveredTransactionIDs),
            forKey: deliveredTransactionsKey
        )
    }
}
