//
//  AnalyticsManager.swift
//  Printer
//
//  Created by Pol on 18/6/25.
//

import Foundation
import FirebaseAnalytics
import StoreKit

class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    
    // Tracking consent flag
    private var isTrackingAllowed = false
    
    private init() {}
    
    // Update tracking consent based on ATT permission
    func updateTrackingConsent(isAllowed: Bool) {
        self.isTrackingAllowed = isAllowed
        
        // Configure Firebase Analytics collection
        Analytics.setAnalyticsCollectionEnabled(isAllowed)
        
        print("📊 Analytics: Tracking consent updated - \(isAllowed ? "ALLOWED" : "DENIED")")
    }
    
    // Private helper to check if tracking is allowed
    private func canTrack() -> Bool {
        return isTrackingAllowed
    }
    
    // MARK: - Subscription Events
    
    /// Track when user successfully subscribes
    func trackSubscriptionPurchase(productID: String, price: String, currency: String = "EUR") {
        guard canTrack() else {
            print("📊 Analytics: Subscription purchase tracking skipped - no consent")
            return
        }
        
        let subscriptionType = getSubscriptionType(from: productID)
        
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterTransactionID: UUID().uuidString,
            AnalyticsParameterItemID: productID,
            AnalyticsParameterItemName: subscriptionType,
            AnalyticsParameterItemCategory: "subscription",
            AnalyticsParameterValue: getPriceValue(from: price),
            AnalyticsParameterCurrency: currency
        ])
        
        // Custom subscription conversion event
        Analytics.logEvent("subscription_conversion", parameters: [
            "subscription_type": subscriptionType,
            "product_id": productID,
            "price": price,
            "currency": currency
        ])
        
        print("📊 Analytics: Tracked subscription purchase - \(subscriptionType)")
    }
    
    /// Track subscription cancellation
    func trackSubscriptionCancellation(productID: String) {
        guard canTrack() else {
            print("📊 Analytics: Subscription cancellation tracking skipped - no consent")
            return
        }
        
        let subscriptionType = getSubscriptionType(from: productID)
        
        Analytics.logEvent("subscription_cancelled", parameters: [
            "subscription_type": subscriptionType,
            "product_id": productID
        ])
        
        print("📊 Analytics: Tracked subscription cancellation - \(subscriptionType)")
    }
    
    /// Track subscription restoration
    func trackSubscriptionRestore(productID: String) {
        guard canTrack() else {
            print("📊 Analytics: Subscription restore tracking skipped - no consent")
            return
        }
        
        let subscriptionType = getSubscriptionType(from: productID)
        
        Analytics.logEvent("subscription_restored", parameters: [
            "subscription_type": subscriptionType,
            "product_id": productID
        ])
        
        print("📊 Analytics: Tracked subscription restore - \(subscriptionType)")
    }
    
    /// Track paywall views
    func trackPaywallView(context: String = "unknown") {
        guard canTrack() else {
            print("📊 Analytics: Paywall view tracking skipped - no consent")
            return
        }
        
        Analytics.logEvent("paywall_viewed", parameters: [
            "context": context,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        print("📊 Analytics: Tracked paywall view - \(context)")
    }
    
    /// Track paywall dismissal
    func trackPaywallDismissed(context: String = "unknown", timeSpent: TimeInterval = 0) {
        guard canTrack() else {
            print("📊 Analytics: Paywall dismissed tracking skipped - no consent")
            return
        }
        
        Analytics.logEvent("paywall_dismissed", parameters: [
            "context": context,
            "time_spent": timeSpent,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        print("📊 Analytics: Tracked paywall dismissed - \(context)")
    }
    
    // MARK: - Feature Usage Events
    
    /// Track when user tries to access premium features
    func trackPremiumFeatureAccess(featureName: String, isSubscribed: Bool) {
        guard canTrack() else {
            print("📊 Analytics: Premium feature access tracking skipped - no consent")
            return
        }
        
        Analytics.logEvent("premium_feature_access", parameters: [
            "feature_name": featureName,
            "is_subscribed": isSubscribed,
            "access_granted": isSubscribed
        ])
        
        print("📊 Analytics: Tracked premium feature access - \(featureName), granted: \(isSubscribed)")
    }
    
    /// Track successful feature usage
    func trackFeatureUsage(featureName: String, isSuccessful: Bool = true) {
        guard canTrack() else {
            print("📊 Analytics: Feature usage tracking skipped - no consent")
            return
        }
        
        Analytics.logEvent("feature_used", parameters: [
            "feature_name": featureName,
            "is_successful": isSuccessful,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        print("📊 Analytics: Tracked feature usage - \(featureName)")
    }
    
    // MARK: - App Flow Events
    
    /// Track onboarding completion
    func trackOnboardingCompleted() {
        guard canTrack() else {
            print("📊 Analytics: Onboarding completion tracking skipped - no consent")
            return
        }
        
        Analytics.logEvent("onboarding_completed", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
        
        print("📊 Analytics: Tracked onboarding completed")
    }
    
    /// Track app launch
    func trackAppLaunch(isFirstLaunch: Bool = false) {
        // Allow app launch tracking even without consent (basic usage analytics)
        Analytics.logEvent("app_launch", parameters: [
            "is_first_launch": isFirstLaunch,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        print("📊 Analytics: Tracked app launch - first: \(isFirstLaunch)")
    }
    
    /// Track ATT permission response
    func trackATTPermissionResponse(granted: Bool) {
        Analytics.logEvent("att_permission_response", parameters: [
            "permission_granted": granted,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        print("📊 Analytics: Tracked ATT permission - \(granted ? "GRANTED" : "DENIED")")
    }
    
    // MARK: - User Properties
    
    /// Set user subscription status
    func setUserSubscriptionStatus(isSubscribed: Bool, subscriptionType: String? = nil) {
        guard canTrack() else {
            print("📊 Analytics: User subscription status tracking skipped - no consent")
            return
        }
        
        Analytics.setUserProperty(isSubscribed ? "premium" : "free", forName: "subscription_status")
        
        if let type = subscriptionType {
            Analytics.setUserProperty(type, forName: "subscription_type")
        }
        
        print("📊 Analytics: Set user subscription status - \(isSubscribed ? "premium" : "free")")
    }
    
    // MARK: - Helper Methods
    
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
    
    private func getPriceValue(from priceString: String) -> Double {
        // Extract numeric value from price string (e.g., "€69.99" -> 69.99)
        let cleanPrice = priceString.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
        let normalizedPrice = cleanPrice.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedPrice) ?? 0.0
    }
}

// MARK: - Analytics Events Extensions

extension AnalyticsManager {
    
    /// Track subscription flow events
    enum SubscriptionFlowEvent: String, CaseIterable {
        case paywallViewed = "paywall_viewed"
        case subscriptionSelected = "subscription_selected"
        case purchaseStarted = "purchase_started"
        case purchaseCompleted = "purchase_completed"
        case purchaseFailed = "purchase_failed"
        case purchaseCancelled = "purchase_cancelled"
        case restoreStarted = "restore_started"
        case restoreCompleted = "restore_completed"
        case restoreFailed = "restore_failed"
    }
    
    func trackSubscriptionFlow(_ event: SubscriptionFlowEvent, parameters: [String: Any] = [:]) {
        guard canTrack() else {
            print("📊 Analytics: Subscription flow tracking skipped - no consent")
            return
        }
        
        var eventParams = parameters
        eventParams["flow_step"] = event.rawValue
        eventParams["timestamp"] = Date().timeIntervalSince1970
        
        Analytics.logEvent(event.rawValue, parameters: eventParams)
        print("📊 Analytics: Tracked subscription flow - \(event.rawValue)")
    }
}
