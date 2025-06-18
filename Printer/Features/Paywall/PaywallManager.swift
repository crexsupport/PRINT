//
//  PaywallManager.swift
//  Printer
//
//  Created by AI Assistant on 17/6/25.
//

import SwiftUI

@MainActor
class PaywallManager: ObservableObject {
    @Published var shouldShowPaywall = false
    @Published var paywallContext: PaywallContext = .afterOnboarding
    
    enum PaywallContext {
        case afterOnboarding
        case afterSplash
        case featureRestricted
    }
    
    func showPaywall(context: PaywallContext) {
        paywallContext = context
        shouldShowPaywall = true
    }
    
    func hidePaywall() {
        shouldShowPaywall = false
    }
    
    func shouldShowAfterOnboarding() -> Bool {
        // Show paywall after onboarding for new users
        return !UserDefaults.standard.bool(forKey: "hasSeenPaywall")
    }
    
    func shouldShowAfterSplash() -> Bool {
        // Show paywall after splash for returning users who haven't subscribed
        let hasSeenPaywall = UserDefaults.standard.bool(forKey: "hasSeenPaywall")
        return hasSeenPaywall && !UserDefaults.standard.bool(forKey: "hasActiveSubscription")
    }
    
    func markPaywallSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenPaywall")
    }
    
    func shouldShowForFeatureRestriction(isSubscribed: Bool) -> Bool {
        return !isSubscribed
    }
}
