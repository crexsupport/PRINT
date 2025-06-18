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
    @State private var selectedProductIndex = 0 // Default to yearly plan
    @State private var showCloseButton = false
    @State private var currentSlideIndex = 0 // 0 = features, 1+ = testimonials
    @State private var hasTrialEnabled = false // Default disabled
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
        "Support +8000 printers"
    ]
    
    let testimonials = [
        ("I wasn't sure if this would work with my new iPad, but it did. It was great!", "Juanita Hudson"),
        ("Perfect for my home office setup. Prints are crisp and clear every time.", "Michael Chen"),
        ("Love the template options. Makes printing labels so much easier.", "Sarah Williams"),
        ("Great app for managing all my printing needs in one place.", "David Rodriguez")
    ]
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()
            
            // Background printer pattern - static positions
            GeometryReader { geometry in
                let topAreaHeight = geometry.size.height * 0.4 // Only top 40% of screen
                
                ForEach(Array(printerPositions.enumerated()), id: \.offset) { index, printerData in
                    Image("paywall_printer")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: printerData.size.width, height: printerData.size.height)
                        .opacity(printerData.opacity)
                        .position(x: printerData.position.x, y: printerData.position.y)
                        .rotationEffect(.degrees(printerData.rotation))
                        .scaleEffect(printerData.scale)
                }
            }
            
            VStack(spacing: 0) {
                // Header with printer image
                headerSection
                
                // Features or Testimonials
                contentSection
                
                // Subscription options
                subscriptionOptionsSection
                
                // Trial toggle
                trialToggleSection
                
                // Purchase button
                purchaseButtonSection
                
                // Legal links
                legalLinksSection
            }
            .padding(.horizontal, 20)
            
            // Close button overlay with bluish color and reduced opacity
            VStack {
                HStack {
                    if showCloseButton {
                        Button(action: {
                            print("Close button tapped - calling dismiss callback")
                            onDismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
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
            
            // Show close button after 3.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCloseButton = true
                }
            }
        }
        .onAppear {
            // Generate static positions only once
            if printerPositions.isEmpty {
                generateStaticPrinterPositions()
            }
        }
        .onDisappear {
            rotationTimer?.invalidate()
            rotationTimer = nil
        }
        .alert("Purchase Result", isPresented: $showingPurchaseResult) {
            Button("OK") {
                if subscriptionManager.isSubscribed {
                    onDismiss()
                }
            }
        } message: {
            Text(purchaseResultMessage)
        }
        .onChange(of: hasTrialEnabled) { oldValue, newValue in
            if newValue {
                selectedProductIndex = 1
            } else {
                selectedProductIndex = 0
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            // Use the custom printer image instead of SF Symbol
            Image("paywall_printer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .padding(.top, 60)
            
            // Title
            Text("Unlock All Features")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    private var contentSection: some View {
        Group {
            if currentSlideIndex == 0 {
                featuresSection
            } else {
                testimonialsSection
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 10) { // REDUCED from 12 to 10
            // Show ALL features at once
            ForEach(features.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16)) // REDUCED from 18 to 16
                        .foregroundColor(.blue)
                    
                    Text(features[index])
                        .font(.system(size: 14, weight: .medium)) // REDUCED from 15 to 14
                        .foregroundColor(.black)
                    
                    Spacer()
                }
            }
            
            // Pagination dots
            HStack(spacing: 4) {
                ForEach(0..<(1 + testimonials.count), id: \.self) { index in
                    Circle()
                        .fill(index == currentSlideIndex ? .blue : .gray.opacity(0.4))
                        .frame(width: 5, height: 5)
                        .scaleEffect(index == currentSlideIndex ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentSlideIndex)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16) // REDUCED from 18 to 16
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .padding(.bottom, 25)
    }
    
    private var testimonialsSection: some View {
        VStack(spacing: 16) {
            // Star rating
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                }
            }
            
            // Testimonial text
            Text(testimonials[currentSlideIndex - 1].0)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // Author
            Text(testimonials[currentSlideIndex - 1].1)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            // Pagination dots
            HStack(spacing: 4) {
                ForEach(0..<(1 + testimonials.count), id: \.self) { index in
                    Circle()
                        .fill(index == currentSlideIndex ? .blue : .gray.opacity(0.4))
                        .frame(width: 5, height: 5)
                        .scaleEffect(index == currentSlideIndex ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentSlideIndex)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18) // MADE CONSISTENT with features section
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .padding(.bottom, 25)
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 10) {
            // Annual plan
            subscriptionOptionCard(
                title: "Yearly Plan",
                price: subscriptionManager.annualProduct?.displayPrice ?? "€69.99",
                weeklyPrice: subscriptionManager.annualProduct != nil ? subscriptionManager.weeklyPrice(for: subscriptionManager.annualProduct!) : "€1.35",
                subtitle: "per week",
                isSelected: selectedProductIndex == 0,
                showCheckmark: selectedProductIndex == 0,
                isHighlighted: selectedProductIndex == 0
            ) {
                selectedProductIndex = 0
                hasTrialEnabled = false
            }
            
            // Weekly plan (shown when trial is disabled)
            if !hasTrialEnabled {
                subscriptionOptionCard(
                    title: "Weekly Plan",
                    price: subscriptionManager.weeklyProduct?.displayPrice ?? "€9.99",
                    weeklyPrice: subscriptionManager.weeklyProduct?.displayPrice ?? "€9.99",
                    subtitle: "per week",
                    isSelected: selectedProductIndex == 2,
                    showCheckmark: selectedProductIndex == 2
                ) {
                    selectedProductIndex = 2
                }
            } else {
                // Weekly trial plan (shown when trial is enabled)
                subscriptionOptionCard(
                    title: "3-day free",
                    price: subscriptionManager.weeklyTrialProduct?.displayPrice ?? "€9.99",
                    weeklyPrice: "then, " + (subscriptionManager.weeklyTrialProduct?.displayPrice ?? "€9.99"),
                    subtitle: "per week",
                    isSelected: selectedProductIndex == 1,
                    showCheckmark: selectedProductIndex == 1
                ) {
                    selectedProductIndex = 1
                }
            }
        }
        .padding(.bottom, 15)
    }
    
    private func subscriptionOptionCard(
        title: String,
        price: String,
        weeklyPrice: String,
        subtitle: String,
        isSelected: Bool,
        showCheckmark: Bool,
        isHighlighted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
            Task {
                await handlePurchase()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(price)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(weeklyPrice)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHighlighted ? Color.blue : (isSelected ? Color.blue : Color.gray.opacity(0.3)), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(subscriptionManager.isLoading)
        .opacity(subscriptionManager.isLoading ? 0.7 : 1.0)
    }
    
    private var trialToggleSection: some View {
        HStack {
            Text("Enable Free Trial")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Toggle("", isOn: $hasTrialEnabled)
                .tint(.blue)
                .scaleEffect(0.9)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.bottom, 15)
    }
    
    private var purchaseButtonSection: some View {
        VStack(spacing: 16) {
            // Show different text based on trial state
            if hasTrialEnabled && selectedProductIndex == 1 {
                // When trial is enabled and trial product is selected
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("No payment now. Cancel anytime.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
            } else {
                // When trial is not enabled (regular subscriptions)
                Text("Auto renewable. Cancel anytime.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Button {
                Task {
                    await handlePurchase()
                }
            } label: {
                HStack {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    
                    Text(buttonText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(subscriptionManager.isLoading)
            .opacity(subscriptionManager.isLoading ? 0.7 : 1.0)
        }
        .padding(.bottom, 16)
    }
    
    private var buttonText: String {
        if hasTrialEnabled && selectedProductIndex == 1 {
            return "Start Free Trial"
        } else {
            return "Continue"
        }
    }
    
    private var legalLinksSection: some View {
        HStack {
            Button("Terms") {
                if let url = URL(string: "https://printer.addonsmcpe.website/terms_conditions.html") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .underline()
            
            Text("&")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button("Privacy") {
                if let url = URL(string: "https://printer.addonsmcpe.website/privacy_policy.html") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .underline()
            
            Text("|")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button("Restore purchase") {
                Task {
                    await subscriptionManager.restorePurchases()
                    if subscriptionManager.isSubscribed {
                        purchaseResultMessage = "Purchases restored successfully!"
                        showingPurchaseResult = true
                    } else if let error = subscriptionManager.error {
                        purchaseResultMessage = error.localizedDescription
                        showingPurchaseResult = true
                    }
                }
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .underline()
        }
        .padding(.bottom, 30)
    }
    
    private func startRotationTimer() {
        rotationTimer?.invalidate()
        
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.8)) {
                // Cycle through: features (0) -> testimonial 1 (1) -> testimonial 2 (2) -> etc.
                let totalSlides = 1 + testimonials.count
                currentSlideIndex = (currentSlideIndex + 1) % totalSlides
            }
        }
    }
    
    private func handlePurchase() async {
        let selectedProduct: Product?
        
        switch selectedProductIndex {
        case 0:
            selectedProduct = subscriptionManager.annualProduct
        case 1:
            selectedProduct = subscriptionManager.weeklyTrialProduct
        case 2:
            selectedProduct = subscriptionManager.weeklyProduct
        default:
            selectedProduct = subscriptionManager.annualProduct
        }
        
        guard let product = selectedProduct else {
            purchaseResultMessage = "Product not available. Please try again."
            showingPurchaseResult = true
            return
        }
        
        let success = await subscriptionManager.purchase(product)
        
        if success {
            purchaseResultMessage = "Purchase successful! You now have access to all premium features."
            showingPurchaseResult = true
        } else if let error = subscriptionManager.error {
            switch error {
            case .userCancelled:
                // Don't show alert for user cancellation
                break
            default:
                purchaseResultMessage = error.localizedDescription
                showingPurchaseResult = true
            }
        }
    }
    
    private func generateNonOverlappingPositions(count: Int, width: CGFloat, height: CGFloat, minDistance: CGFloat) -> [CGPoint] {
        var positions: [CGPoint] = []
        let maxAttempts = 100
        
        for _ in 0..<count {
            var attempts = 0
            var newPosition: CGPoint
            
            repeat {
                newPosition = CGPoint(
                    x: CGFloat.random(in: minDistance...(width - minDistance)),
                    y: CGFloat.random(in: minDistance...(height - minDistance))
                )
                attempts += 1
            } while attempts < maxAttempts && positions.contains { position in
                let distance = sqrt(pow(newPosition.x - position.x, 2) + pow(newPosition.y - position.y, 2))
                return distance < minDistance
            }
            
            if attempts < maxAttempts {
                positions.append(newPosition)
            }
        }
        
        return positions
    }
    
    private func generateStaticPrinterPositions() {
        let count = 12
        let minDistance: CGFloat = 50
        
        // Use screen bounds as default size
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height * 0.4 // Top 40%
        
        let positions = generateNonOverlappingPositions(
            count: count,
            width: screenWidth,
            height: screenHeight,
            minDistance: minDistance
        )
        
        printerPositions = positions.map { position in
            PrinterPosition(
                position: position,
                size: CGSize(
                    width: CGFloat.random(in: 24...32),
                    height: CGFloat.random(in: 24...32)
                ),
                opacity: Double.random(in: 0.04...0.08),
                rotation: Double.random(in: -15...15),
                scale: Double.random(in: 0.8...1.2)
            )
        }
    }
}

#Preview {
    PaywallView()
}
