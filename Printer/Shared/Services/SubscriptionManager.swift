//
//  SubscriptionManager.swift
//  Printer
//
//  Created by AI Assistant on 17/6/25.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    
    private let productIDs: Set<String> = [
        "com.blastlystudios.smartprinter.annual",
        "com.blastlystudios.smartprinter.weekly",
        "com.blastlystudios.smartprinter.weeklytrial"
    ]
    
    private var transactionUpdatesTask: Task<Void, Never>?
    
    init() {
        transactionUpdatesTask = Task {
            await startTransactionMonitoring()
        }
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        transactionUpdatesTask?.cancel()
    }
    
    private func startTransactionMonitoring() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                print("SubscriptionManager: Received transaction update for \(transaction.productID)")
                
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    AnalyticsManager.shared.trackSubscriptionPurchase(
                        productID: transaction.productID,
                        price: product.displayPrice
                    )
                }
                
                await updateSubscriptionStatus()
                await transaction.finish()
            } catch {
                print("SubscriptionManager: Transaction verification failed: \(error)")
            }
        }
    }
    
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let products = try await Product.products(for: productIDs)
            self.products = products.sorted { product1, product2 in
                // Sort by product type and price
                if product1.id.contains("annual") { return true }
                if product2.id.contains("annual") { return false }
                if product1.id.contains("weeklytrial") { return true }
                if product2.id.contains("weeklytrial") { return false }
                return false
            }
            print("SubscriptionManager: Loaded \(products.count) products")
            for product in products {
                print("Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            self.error = .failedToLoadProducts(error.localizedDescription)
            print("SubscriptionManager Error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        error = nil
        
        AnalyticsManager.shared.trackSubscriptionFlow(.purchaseStarted, parameters: [
            "product_id": product.id,
            "price": product.displayPrice
        ])
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                AnalyticsManager.shared.trackSubscriptionPurchase(
                    productID: product.id,
                    price: product.displayPrice
                )
                AnalyticsManager.shared.trackSubscriptionFlow(.purchaseCompleted, parameters: [
                    "product_id": product.id,
                    "price": product.displayPrice
                ])
                
                await transaction.finish()
                await updateSubscriptionStatus()
                isLoading = false
                return true
                
            case .userCancelled:
                error = .userCancelled
                AnalyticsManager.shared.trackSubscriptionFlow(.purchaseCancelled, parameters: [
                    "product_id": product.id
                ])
                isLoading = false
                return false
                
            case .pending:
                error = .purchasePending
                isLoading = false
                return false
                
            @unknown default:
                error = .unknownError
                AnalyticsManager.shared.trackSubscriptionFlow(.purchaseFailed, parameters: [
                    "product_id": product.id,
                    "error": "unknown_result"
                ])
                isLoading = false
                return false
            }
        } catch {
            self.error = .purchaseFailed(error.localizedDescription)
            print("Purchase error: \(error.localizedDescription)")
            
            AnalyticsManager.shared.trackSubscriptionFlow(.purchaseFailed, parameters: [
                "product_id": product.id,
                "error": error.localizedDescription
            ])
            
            isLoading = false
            return false
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        error = nil
        
        AnalyticsManager.shared.trackSubscriptionFlow(.restoreStarted)
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            AnalyticsManager.shared.trackSubscriptionFlow(.restoreCompleted)
            
            // Track individual restored subscriptions
            for productID in purchasedProductIDs {
                AnalyticsManager.shared.trackSubscriptionRestore(productID: productID)
            }
            
        } catch {
            self.error = .restoreFailed(error.localizedDescription)
            
            AnalyticsManager.shared.trackSubscriptionFlow(.restoreFailed, parameters: [
                "error": error.localizedDescription
            ])
        }
        
        isLoading = false
    }
    
    private func updateSubscriptionStatus() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProducts.insert(transaction.productID)
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        let wasSubscribed = self.isSubscribed
        self.purchasedProductIDs = purchasedProducts
        self.isSubscribed = !purchasedProducts.isEmpty
        
        // Update UserDefaults for consistency
        UserDefaults.standard.set(isSubscribed, forKey: "hasActiveSubscription")
        print("SubscriptionManager: Subscription status updated - \(isSubscribed)")
        
        if wasSubscribed != isSubscribed {
            let subscriptionType = purchasedProducts.first.map { getSubscriptionType(from: $0) }
            AnalyticsManager.shared.setUserSubscriptionStatus(
                isSubscribed: isSubscribed,
                subscriptionType: subscriptionType
            )
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.transactionVerificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Product Helpers
    
    var annualProduct: Product? {
        products.first { $0.id == "com.blastlystudios.smartprinter.annual" }
    }
    
    var weeklyProduct: Product? {
        products.first { $0.id == "com.blastlystudios.smartprinter.weekly" }
    }
    
    var weeklyTrialProduct: Product? {
        products.first { $0.id == "com.blastlystudios.smartprinter.weeklytrial" }
    }
    
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    func weeklyPrice(for product: Product) -> String {
        if product.id.contains("annual") {
            // Calculate weekly price for annual subscription (69.99 / 52 weeks)
            let annualPrice = 69.99
            let weeklyPrice = annualPrice / 52
            return String(format: "%.2f €", weeklyPrice)
        }
        return product.displayPrice
    }
    
    private func getSubscriptionType(from productID: String) -> String {
        if productID.contains("annual") {
            return "yearly"
        } else if productID.contains("weeklytrial") {
            return "weekly_trial"
        } else if productID.contains("weekly") {
            return "weekly"
        }
        return "unknown"
    }
}

enum SubscriptionError: LocalizedError {
    case failedToLoadProducts(String)
    case purchaseFailed(String)
    case userCancelled
    case purchasePending
    case restoreFailed(String)
    case transactionVerificationFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadProducts(let message):
            return "Failed to load products: \(message)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .userCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .restoreFailed(let message):
            return "Failed to restore purchases: \(message)"
        case .transactionVerificationFailed:
            return "Transaction verification failed"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
