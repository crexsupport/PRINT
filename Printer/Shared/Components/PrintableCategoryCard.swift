//
//  PrintableCategoryCard.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct PrintableCategoryCard: View {
    let category: PrintableCategory
    let subscriptionManager: SubscriptionManager
    let paywallManager: PaywallManager
    @StateObject private var printablesManager = PrintablesManager()
    @State private var showingCategoryView = false
    
    private var items: [PrintableItem] {
        printablesManager.printables(for: category)
    }
    
    var body: some View {
        Button(action: {
            showingCategoryView = true
        }) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(category.color)
                    .frame(width: 60, height: 60)
                    .background(category.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Text
                VStack(spacing: 4) {
                    Text(category.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "\(items.count) items"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingCategoryView) {
            PrintableCategoryView(
                category: category,
                items: items,
                onPaywallTrigger: {
                    // Cerrar la vista de categoría y mostrar paywall
                    showingCategoryView = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        paywallManager.shouldShowPaywall = true
                    }
                }
            )
            .environmentObject(subscriptionManager)
        }
    }
}