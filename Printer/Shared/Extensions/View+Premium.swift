//
//  View+Premium.swift
//  Printer
//
//  Created by AI Assistant on 17/6/25.
//

import SwiftUI

extension View {
    func premiumGate(
        _ subscriptionManager: SubscriptionManager,
        _ paywallManager: PaywallManager
    ) -> some View {
        self.modifier(PremiumGateModifier(
            subscriptionManager: subscriptionManager,
            paywallManager: paywallManager
        ))
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
