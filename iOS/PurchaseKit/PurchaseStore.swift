import Foundation
import StoreKit
import Combine

@MainActor
final class PurchaseStore: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case purchasing
        case purchased
        case pending
        case cancelled
        case failed(String)
        case restoring
        case restored
    }

    @Published private(set) var product: Product?
    @Published private(set) var state: State = .idle
    @Published private(set) var isUnlocked = false
    private let productID: String
    private var transactionTask: Task<Void, Never>?

    init(productID: String) {
        self.productID = productID
        transactionTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }

    var displayPrice: String? {
        product?.displayPrice
    }

    var statusText: String {
        switch state {
        case .idle, .ready:
            return "可購買或恢復 Pro。"
        case .loading:
            return "正在載入 StoreKit 商品。"
        case .purchasing:
            return "正在連線 App Store。"
        case .purchased, .restored:
            return "Pro 已解鎖。"
        case .pending:
            return "付款待確認，完成後會自動解鎖。"
        case .cancelled:
            return "已取消購買。"
        case .failed(let message):
            return message
        case .restoring:
            return "正在恢復購買。"
        }
    }

    func load() async {
        guard product == nil else { return }
        state = .loading
        do {
            product = try await Product.products(for: [productID]).first
            state = product == nil ? .failed("找不到 StoreKit 商品。") : .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func purchase() async {
        guard let product else {
            state = .failed("購買資訊尚未載入。")
            return
        }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    state = .purchased
                } else {
                    state = .failed("交易驗證失敗。")
                }
            case .pending:
                state = .pending
            case .userCancelled:
                state = .cancelled
            @unknown default:
                state = .failed("未知購買狀態。")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        state = .restoring
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            state = .restored
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == productID {
                unlocked = true
                break
            }
        }
        isUnlocked = unlocked
    }
}
