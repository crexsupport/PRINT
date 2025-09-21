//
//  View+Premium.swift
//  Printer
//
//  Created by Pol on 17/6/25.
//

import SwiftUI

extension View {
    func requiresPremium(
        featureName: String,
        subscriptionManager: SubscriptionManager,
        paywallManager: PaywallManager
    ) -> some View {
        self.onTapGesture {
            AnalyticsManager.shared.trackPremiumFeatureAccess(
                featureName: featureName,
                isSubscribed: subscriptionManager.isSubscribed
            )
            
            if !subscriptionManager.isSubscribed {
                paywallManager.showPaywall(context: .featureRestricted)
            }
        }
    }
}

struct PremiumGateModifier: ViewModifier {
    let subscriptionManager: SubscriptionManager
    let paywallManager: PaywallManager
    
    func body(content: Content) -> some View {
        content
            .disabled(!subscriptionManager.isSubscribed)
            .overlay(
                !subscriptionManager.isSubscribed ? 
                Color.black.opacity(0.1) : Color.clear
            )
            .onTapGesture {
                if !subscriptionManager.isSubscribed {
                    paywallManager.showPaywall(context: .featureRestricted)
                }
            }
    }
}
