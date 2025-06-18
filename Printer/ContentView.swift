//
//  ContentView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
            .environmentObject(SubscriptionManager())
            .environmentObject(PaywallManager())
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}
