//
//  StoreManager.swift
//  MbMajiang
//

import StoreKit
import Observation

@Observable
final class StoreManager {
    static let shared = StoreManager()

    enum ProductID: String, CaseIterable {
        case detailedColors = "ryu_nakamura.MbMajiang.detailedColors"
        case borderTheme    = "ryu_nakamura.MbMajiang.borderTheme"
        case canvasTheme    = "ryu_nakamura.MbMajiang.canvasTheme"
    }

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var lastErrorMessage: String?
    var restoreResultMessage: String?

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactionUpdates()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// 詳細設定（牌デザイン表・裏・背景のRGB自由選択）が使えるか
    var hasDetailedColors: Bool {
        purchasedProductIDs.contains(ProductID.detailedColors.rawValue)
    }

    /// 牌デザイン（裏）のボーダーテーマが使えるか
    var hasBorderTheme: Bool {
        purchasedProductIDs.contains(ProductID.borderTheme.rawValue)
    }

    /// 背景の「キャンバス」テーマ（手書き機能）が使えるか
    var hasCanvasTheme: Bool {
        purchasedProductIDs.contains(ProductID.canvasTheme.rawValue)
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            lastErrorMessage = "商品の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                    return true
                }
                lastErrorMessage = "購入の検証に失敗しました"
                return false
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = "購入に失敗しました: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        let previouslyOwned = purchasedProductIDs
        try? await AppStore.sync()
        await updatePurchasedProducts()
        restoreResultMessage = purchasedProductIDs == previouslyOwned ? "復元できる購入履歴が見つかりませんでした" : "購入履歴を復元しました"
    }

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self?.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }
}
