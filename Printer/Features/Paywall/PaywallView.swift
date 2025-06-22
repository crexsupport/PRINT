//
//  PaywallView.swift
//  Printer
//
//  Created by AI Assistant on 17/6/25.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProductIndex = 1 // Default to trial plan if available
    @State private var showCloseButton = false
    @State private var currentSlideIndex = 0 // 0 = features, 1+ = testimonials
    @State private var hasTrialEnabled = true // Default trial enabled
    @State private var rotationTimer: Timer?
    @State private var showingPurchaseResult = false
    @State private var purchaseResultMessage = ""
    
    @State private var printerPositions: [PrinterPosition] = []
    
    let onDismiss: () -> Void
    
    init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }
    
    private struct PrinterPosition {
        let position: CGPoint
        let size: CGSize
        let opacity: Double
        let rotation: Double
        let scale: Double
    }

    let features = [
        "Unlimited print",
        "Powerful edit tools",
        "Support +9000 printers"
    ]
    
    let testimonials = [
        ("I wasn't sure if this would work with my new iPad, but it did. It was great!", "Juanita Hudson"),
        ("Perfect for my home office setup. Prints are crisp and clear every time.", "Michael Chen"),
        ("Love the template options. Makes printing labels so much easier.", "Sarah Williams"),
        ("Great app for managing all my printing needs in one place.", "David Rodriguez")
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            GeometryReader { geometry in
                ForEach(Array(printerPositions.enumerated()), id: \.offset) { index, printerData in
                    Image("paywall_printer")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: printerData.size.width, height: printerData.size.height)
                        .opacity(printerData.opacity).position(x: printerData.position.x, y: printerData.position.y)
                        .rotationEffect(.degrees(printerData.rotation)).scaleEffect(printerData.scale)
                }
            }
            
            VStack(spacing: 0) {
                headerSection
                contentSection
                trialToggleSection
                subscriptionOptionsSection
                purchaseButtonSection
                legalLinksSection
            }
            .padding(.horizontal, 20)
            
            VStack {
                HStack {
                    if showCloseButton {
                        Button(action: { onDismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium)).foregroundColor(.blue.opacity(0.3))
                                .frame(width: 44, height: 44).background(Color.white.opacity(0.05)).clipShape(Circle())
                        }
                        .padding(.top, 40)
                        .padding(.leading, 20)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task {
            await subscriptionManager.loadProducts()
            startRotationTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) { // Close button delay
                withAnimation(.easeInOut(duration: 0.3)) { showCloseButton = true }
            }
        }
        .onAppear {
            if printerPositions.isEmpty { generateStaticPrinterPositions() }
            // Ensure selectedProductIndex reflects trial state on appear
            if hasTrialEnabled && subscriptionManager.weeklyTrialProduct != nil {
                selectedProductIndex = 1 // Trial
            } else if subscriptionManager.annualProduct != nil {
                selectedProductIndex = 0 // Annual
            } else {
                selectedProductIndex = 2 // Weekly (fallback)
            }
        }
        .onDisappear { rotationTimer?.invalidate(); rotationTimer = nil }
        .alert("Purchase Result", isPresented: $showingPurchaseResult) {
            Button("OK") { if subscriptionManager.isSubscribed { onDismiss() } }
        } message: { Text(purchaseResultMessage) }
        .onChange(of: hasTrialEnabled) { _, newValue in
             // When trial is enabled, select trial product (index 1)
             // When trial is disabled, select annual product (index 0)
            selectedProductIndex = newValue ? 1 : 0
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image("paywall_printer").resizable().aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140).padding(.top, 60)
            Text("UNLOCK ALL FEATURES").font(.system(size: 23, weight: .bold))
                .foregroundColor(.black).multilineTextAlignment(.center)
        }.padding(.bottom, 20)
    }
    
    private var contentSection: some View {
        Group {
            if currentSlideIndex == 0 { featuresSection } else { testimonialsSection }
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 10) {
            ForEach(features.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundColor(.blue)
                    Text(features[index]).font(.system(size: 14, weight: .medium)).foregroundColor(.black)
                    Spacer()
                }
            }
            HStack(spacing: 4) {
                ForEach(0..<(1 + testimonials.count), id: \.self) { idx in
                    Circle().fill(idx == currentSlideIndex ? .blue : .gray.opacity(0.4))
                        .frame(width: 5, height: 5).scaleEffect(idx == currentSlideIndex ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentSlideIndex)
                }
            }.padding(.top, 8)
        }.padding(.horizontal, 20).padding(.vertical, 16)
        .background(Color.blue.opacity(0.05)).cornerRadius(16).padding(.bottom, 25)
    }
    
    private var testimonialsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) { ForEach(0..<5, id: \.self) { _ in Image(systemName: "star.fill").font(.system(size: 16)).foregroundColor(.orange) } }
            Text(testimonials[currentSlideIndex - 1].0).font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.center).lineLimit(3)
            Text(testimonials[currentSlideIndex - 1].1).font(.system(size: 14, weight: .medium)).foregroundColor(.black)
            HStack(spacing: 4) {
                ForEach(0..<(1 + testimonials.count), id: \.self) { idx in
                    Circle().fill(idx == currentSlideIndex ? .blue : .gray.opacity(0.4))
                        .frame(width: 5, height: 5).scaleEffect(idx == currentSlideIndex ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentSlideIndex)
                }
            }.padding(.top, 8)
        }.padding(.horizontal, 20).padding(.vertical, 18)
        .background(Color.blue.opacity(0.05)).cornerRadius(16).padding(.bottom, 25)
    }

    private var trialToggleSection: some View {
        HStack {
            Text("Enable Free Trial").font(.system(size: 15, weight: .medium)).foregroundColor(.black)
            Spacer()
            Toggle("", isOn: $hasTrialEnabled).tint(.blue).scaleEffect(0.9)
        }.padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))
        .padding(.bottom, 15)
    }

    private var subscriptionOptionsSection: some View {
        VStack(spacing: 10) {
            if let annualProduct = subscriptionManager.annualProduct {
                subscriptionOptionCard(product: annualProduct, productType: .annual, isSelected: selectedProductIndex == 0) {
                    selectedProductIndex = 0
                    hasTrialEnabled = false // Selecting annual disables trial toggle
                }
            }

            if hasTrialEnabled {
                if let weeklyTrialProduct = subscriptionManager.weeklyTrialProduct {
                    subscriptionOptionCard(product: weeklyTrialProduct, productType: .weeklyTrial, isSelected: selectedProductIndex == 1) {
                        selectedProductIndex = 1
                        // hasTrialEnabled remains true
                    }
                }
            } else {
                if let weeklyProduct = subscriptionManager.weeklyProduct {
                     subscriptionOptionCard(product: weeklyProduct, productType: .weeklyNoTrial, isSelected: selectedProductIndex == 2) {
                        selectedProductIndex = 2
                        // hasTrialEnabled remains false
                    }
                }
            }
        }
        .padding(.bottom, 15)
    }

    enum ProductCardType { case annual, weeklyTrial, weeklyNoTrial }

    private func subscriptionOptionCard(product: Product, productType: ProductCardType, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            Task {
                await handlePurchase()
            }
        }) {
            HStack(spacing: 8) { // Added spacing for overall HStack
                // Left Column
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleForProduct(productType: productType, hasTrialEnabled: hasTrialEnabled))
                        .font(.system(size: 14, weight: .semibold)) // Adjusted title font
                        .foregroundColor(Color.black.opacity(0.75))
                    
                    Text(priceStringForProduct(product: product, productType: productType, hasTrialEnabled: hasTrialEnabled))
                        .font(.system(size: 12, weight: .regular)) // Adjusted price font
                        .foregroundColor(Color.gray)
                }
                .padding(.vertical, 5) // Add some vertical padding to left column text

                Spacer()

                // Right Column
                VStack(alignment: .trailing, spacing: 4) {
                    if productType == .annual {
                        Text("BEST OFFER")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isSelected ? Color.blue : Color.gray.opacity(0.7))
                            .cornerRadius(4)
                        Text(subscriptionManager.weeklyPrice(for: product) + "/week" )
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.gray)
                    } else if productType == .weeklyTrial {
                        Text("3 DAYS FREE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(4)
                        // No secondary price text here as per image
                    } else { // weeklyNoTrial
                        // This space will now be empty for weeklyNoTrial on the right, as per implied design.
                        // If something else should go here, it needs to be specified.
                    }
                }
                 .padding(.vertical, 5) // Add some vertical padding to right column text
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10) // Slightly reduced overall vertical padding
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1.5) // Bolder selected border
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Helper to get title based on product type and trial state
    private func titleForProduct(productType: ProductCardType, hasTrialEnabled: Bool) -> String {
        switch productType {
        case .annual:
            return "YEARLY ACCESS"
        case .weeklyTrial:
            return "FIRST 3 DAYS FREE"
        case .weeklyNoTrial:
            return "WEEKLY ACCESS"
        }
    }

    // Helper to get price string based on product type and trial state
    private func priceStringForProduct(product: Product, productType: ProductCardType, hasTrialEnabled: Bool) -> String {
        let periodSuffix = subscriptionManager.billingPeriodSuffix(for: product)
        switch productType {
        case .annual:
            return product.displayPrice + periodSuffix
        case .weeklyTrial:
            return "then " + product.displayPrice + periodSuffix
        case .weeklyNoTrial:
            return product.displayPrice + periodSuffix
        }
    }

    private var purchaseButtonSection: some View {
        VStack(spacing: 8) { // Reduced spacing
            Button { Task { await handlePurchase() } } label: {
                HStack {
                    if subscriptionManager.isLoading { ProgressView().scaleEffect(0.8).tint(.white) }
                    Text(buttonText).font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                }.frame(maxWidth: .infinity).padding(.vertical, 18) // Taller button
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                )
                .cornerRadius(12)
            }.disabled(subscriptionManager.isLoading).opacity(subscriptionManager.isLoading ? 0.7 : 1.0)
            
            Group { // Grouping for consistent font and color
                if hasTrialEnabled && selectedProductIndex == 1 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 13)).foregroundColor(.green)
                        Text("NO PAYMENT NOW")
                    }
                } else {
                    Text("Auto renewable. Cancel anytime.")
                }
            }
            .font(.system(size: 11, weight: .medium)) // Adjusted font size
            .foregroundColor(.gray)
            
        }
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    private var buttonText: String {
        if hasTrialEnabled && selectedProductIndex == 1 { return "TRY FOR FREE" } // Changed CTA
        else { return "CONTINUE" }
    }
    
    private var legalLinksSection: some View {
        HStack(spacing: 8) { // Added spacing
            Button(action: { if let url = URL(string: "https://printer.addonsmcpe.website/terms_conditions.html") { UIApplication.shared.open(url) } }) {
                Text("Terms").font(.system(size: 13, weight: .regular)).underline().foregroundColor(.gray)
            }
            Text("&").font(.system(size: 13, weight: .regular)).foregroundColor(.gray)
            Button(action: { if let url = URL(string: "https://printer.addonsmcpe.website/privacy_policy.html") { UIApplication.shared.open(url) } }) {
                Text("Privacy").font(.system(size: 13, weight: .regular)).underline().foregroundColor(.gray)
            }
            Text("|").font(.system(size: 13, weight: .regular)).foregroundColor(.gray)
            Button(action: {
                Task {
                    // FIX: Corrected the method call to subscriptionManager.restorePurchases()
                    await subscriptionManager.restorePurchases()
                    if subscriptionManager.isSubscribed {
                        purchaseResultMessage = "Purchases restored successfully!"
                        showingPurchaseResult = true
                    } else if let error = subscriptionManager.error {
                        purchaseResultMessage = error.localizedDescription
                        showingPurchaseResult = true
                    }
                }
            }) {
                Text("Restore").font(.system(size: 13, weight: .regular)).underline().foregroundColor(.gray)
            }
        }.padding(.bottom, 30)
    }
    
    private func startRotationTimer() {
        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                currentSlideIndex = (currentSlideIndex + 1) % (1 + testimonials.count)
            }
        }
    }
    
    private func handlePurchase() async {
        let productToPurchase: Product?
        switch selectedProductIndex {
        case 0: productToPurchase = subscriptionManager.annualProduct
        case 1: productToPurchase = subscriptionManager.weeklyTrialProduct
        case 2: productToPurchase = subscriptionManager.weeklyProduct
        default: productToPurchase = nil
        }
        
        guard let product = productToPurchase else {
            purchaseResultMessage = "Product not available. Please try again."
            showingPurchaseResult = true
            return
        }
        
        let success = await subscriptionManager.purchase(product)

        if success {
            purchaseResultMessage = "Purchase successful! You now have access to all premium features."
            showingPurchaseResult = true
        } else {
            if let currentError = subscriptionManager.error {
                if case .userCancelled = currentError {
                } else {
                    purchaseResultMessage = currentError.localizedDescription
                    showingPurchaseResult = true
                }
            } else {
                purchaseResultMessage = "An unknown error occurred during purchase."
                showingPurchaseResult = true
            }
        }
    }
    
    private func generateStaticPrinterPositions() {
        let count = 12; let minDistance: CGFloat = 50
        let screenWidth = UIScreen.main.bounds.width; let screenHeight = UIScreen.main.bounds.height * 0.4
        let positions = generateNonOverlappingPositions(count: count, width: screenWidth, height: screenHeight, minDistance: minDistance)
        printerPositions = positions.map { PrinterPosition(position: $0, size: CGSize(width: CGFloat.random(in: 24...32), height: CGFloat.random(in: 24...32)), opacity: Double.random(in: 0.04...0.08), rotation: Double.random(in: -15...15), scale: Double.random(in: 0.8...1.2)) }
    }

    private func generateNonOverlappingPositions(count: Int, width: CGFloat, height: CGFloat, minDistance: CGFloat) -> [CGPoint] {
        var positions: [CGPoint] = []; let maxAttempts = 100
        for _ in 0..<count {
            var attempts = 0; var newPosition: CGPoint
            repeat {
                newPosition = CGPoint(x: CGFloat.random(in: minDistance...(width - minDistance)), y: CGFloat.random(in: minDistance...(height - minDistance)))
                attempts += 1
            } while attempts < maxAttempts && positions.contains { pos in sqrt(pow(newPosition.x - pos.x, 2) + pow(newPosition.y - pos.y, 2)) < minDistance }
            if attempts < maxAttempts { positions.append(newPosition) }
        }
        return positions
    }
}

#Preview { PaywallView().environmentObject(SubscriptionManager()) }
