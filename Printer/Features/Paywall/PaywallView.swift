//
//  PaywallView.swift
//  Printer
//
//  Created by Pol on 17/6/25.
//

import SwiftUI
import StoreKit
import Lottie

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProductIndex = 1 // Default to trial plan if available
    @State private var showCloseButton = false
    @State private var currentSlideIndex = 0 // 0 = features, 1+ = testimonials
    @State private var hasTrialEnabled = true // Default trial enabled
    @State private var rotationTimer: Timer?
    @State private var showingPurchaseResult = false
    @State private var purchaseResultMessage = ""
    @State private var animationRotation: Double = 0
    @State private var buttonBreathingScale: Double = 1.0
    
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

    private let animatedIcons = [
        ("folder", Color(red: 0.2, green: 0.5, blue: 0.9)),        // Blue tone
        ("photo", Color(red: 0.9, green: 0.6, blue: 0.2)),         // Orange tone  
        ("doc.text", Color(red: 0.9, green: 0.3, blue: 0.3)),      // Red tone
        ("doc.viewfinder", Color(red: 0.3, green: 0.7, blue: 0.4)) // Green tone
    ]

    let features = [
        String(localized: "Unlimited printing"),
        String(localized: "Access to all templates"), 
        String(localized: "Priority customer support")
    ]
    
    let reviews = [
        (text: String(localized: "I love this app! Printing from my phone is so easy now. Works perfectly with my printer."), author: "Richard78", rating: 5),
        (text: String(localized: "Great app for my home setup. Works perfectly every time and has lots of useful features."), author: "Maria_G", rating: 5),
        (text: String(localized: "Finally an app that actually works. Very user friendly and saves me so much time."), author: "CarlosT", rating: 5),
        (text: String(localized: "Best printing app I've tried. Worth every penny and the support is excellent too."), author: "Ana_M", rating: 5)
    ]
    
    var body: some View {
        ZStack {
            // Slightly more subtle background for Paywall
            Color(red: 0.975, green: 0.975, blue: 0.975)
                .ignoresSafeArea()
            
            // Pattern overlay with printer-related shapes
            GeometryReader { geometry in
                Canvas { context, size in
                    // Create pattern of printer-related shapes - slightly larger
                    let shapes: [(CGPoint, CGFloat, String)] = [
                        (CGPoint(x: size.width * 0.15, y: size.height * 0.12), 42, "paper"),
                        (CGPoint(x: size.width * 0.85, y: size.height * 0.18), 44, "folder"),
                        (CGPoint(x: size.width * 0.25, y: size.height * 0.35), 42, "square"),
                        (CGPoint(x: size.width * 0.75, y: size.height * 0.28), 39, "paper"),
                        (CGPoint(x: size.width * 0.05, y: size.height * 0.55), 40, "folder"),
                        (CGPoint(x: size.width * 0.95, y: size.height * 0.45), 48, "square"),
                        (CGPoint(x: size.width * 0.35, y: size.height * 0.65), 37, "paper"),
                        (CGPoint(x: size.width * 0.65, y: size.height * 0.75), 42, "folder"),
                        (CGPoint(x: size.width * 0.15, y: size.height * 0.85), 46, "square"),
                        (CGPoint(x: size.width * 0.85, y: size.height * 0.92), 34, "paper"),
                        (CGPoint(x: size.width * 0.45, y: size.height * 0.08), 38, "folder"),
                        (CGPoint(x: size.width * 0.55, y: size.height * 0.48), 44, "square")
                    ]
                    
                    for (point, size, shape) in shapes {
                        context.opacity = 0.10 // Slightly more visible (was 0.08)
                        
                        switch shape {
                        case "paper":
                            // Paper shape with folded top corner and wider proportions
                            let path = Path { p in
                                let width = size * 0.75    // Wider paper
                                let height = size * 1.0    // Good height proportion
                                let foldSize = size * 0.15  // Size of folded corner
                                
                                let rect = CGRect(
                                    x: point.x - width/2,
                                    y: point.y - height/2,
                                    width: width,
                                    height: height
                                )
                                
                                // Main paper body with folded corner
                                p.move(to: CGPoint(x: rect.minX, y: rect.minY))
                                p.addLine(to: CGPoint(x: rect.maxX - foldSize, y: rect.minY))
                                p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + foldSize))
                                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                                p.closeSubpath()
                                
                                // Folded corner triangle (darker to show fold)
                                p.move(to: CGPoint(x: rect.maxX - foldSize, y: rect.minY))
                                p.addLine(to: CGPoint(x: rect.maxX - foldSize, y: rect.minY + foldSize))
                                p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + foldSize))
                                p.closeSubpath()
                            }
                            context.fill(path, with: .color(.gray))
                            
                        case "folder":
                            // Folder shape with tab
                            let path = Path { p in
                                let width = size * 0.8
                                let height = size * 0.65
                                let tabWidth = width * 0.4
                                let tabHeight = height * 0.2
                                
                                let rect = CGRect(
                                    x: point.x - width/2,
                                    y: point.y - height/2,
                                    width: width,
                                    height: height
                                )
                                
                                // Main folder body
                                p.addRoundedRect(in: rect, cornerSize: CGSize(width: 3, height: 3))
                                
                                // Folder tab
                                let tabRect = CGRect(
                                    x: rect.minX + width * 0.1,
                                    y: rect.minY - tabHeight,
                                    width: tabWidth,
                                    height: tabHeight
                                )
                                p.addRoundedRect(in: tabRect, cornerSize: CGSize(width: 2, height: 2))
                            }
                            context.fill(path, with: .color(.gray))
                            
                        case "square":
                            context.fill(
                                Path(CGRect(
                                    x: point.x - size/2,
                                    y: point.y - size/2,
                                    width: size,
                                    height: size
                                )),
                                with: .color(.gray)
                            )
                        default:
                            break
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
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
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 28, height: 28)
                                .background(Color.clear)
                        }
                        .opacity(0.6)
                        .padding(.top, 50)
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
            withAnimation(.easeInOut(duration: 0.3)) { showCloseButton = true }
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
        .alert(String(localized: "Purchase Result"), isPresented: $showingPurchaseResult) {
            Button(String(localized: "OK")) { if subscriptionManager.isSubscribed { onDismiss() } }
        } message: { Text(purchaseResultMessage) }
        .onChange(of: hasTrialEnabled) { _, newValue in
             // When trial is enabled, select trial product (index 1)
             // When trial is disabled, select annual product (index 0)
            selectedProductIndex = newValue ? 1 : 0
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            ZStack {
                // Floating elements around the printer (static positions matching reference)
                ForEach(0..<4, id: \.self) { index in
                    Image(systemName: animatedIcons[index].0)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(animatedIcons[index].1)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            animatedIcons[index].1.opacity(0.12),
                                            animatedIcons[index].1.opacity(0.02)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
                        )
                        .offset(
                            x: referencePositions[index].width + sin(animationRotation * 1.2 + Double(index) * 1.5) * 2,
                            y: referencePositions[index].height + cos(animationRotation * 0.9 + Double(index) * 1.2) * 4
                        )
                }
                
                // Lottie animation in fixed container to prevent layout changes - faster playback
                LottieView(animation: .named("printer_paywall_animation"))
                    .playing(loopMode: .loop)
                    .animationSpeed(1.6) // Make animation 30% faster
                    .frame(width: 200, height: 200)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                    .clipped() // Ensures the animation doesn't overflow its bounds
            }
            .frame(height: 140) // Fixed height container to prevent movement
            .padding(.top, 60)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animationRotation = 1.0
                }
            }
            
            Text("Unlimited access").font(.system(size: 25, weight: .bold))
                .foregroundColor(.black).multilineTextAlignment(.center)
        }.padding(.bottom, 20)
    }

    // Positions matching the reference image more precisely
    private var referencePositions: [CGSize] {
        [
            CGSize(width: -95, height: -45),   // Top left (folder - blue)
            CGSize(width: 95, height: -45),    // Top right (photo - orange) - same height as folder
            CGSize(width: -110, height: 25),   // Bottom left (doc.text - red)  
            CGSize(width: 110, height: 25)     // Bottom right (scanner - green) - same height as doc.text
        ]
    }
    
    private var contentSection: some View {
        VStack(spacing: 16) {
            Group {
                if currentSlideIndex == 0 { 
                    featuresSection 
                } else { 
                    reviewsSection 
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1), value: currentSlideIndex) // Smoother spring animation
            .id(currentSlideIndex) // Force view recreation for smooth animation
            
            // Dots indicator outside the box
            HStack(spacing: 4) {
                ForEach(0..<(1 + reviews.count), id: \.self) { idx in
                    Circle()
                        .fill(idx == currentSlideIndex ? Color(red: 0.15, green: 0.4, blue: 0.8) : .gray.opacity(0.4))
                        .frame(width: 6, height: 6)
                        .scaleEffect(idx == currentSlideIndex ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentSlideIndex) // Smooth spring for dots
                }
            }
            .padding(.bottom, 11)
        }
    }

    private var reviewsSection: some View {
        let currentReview = reviews[currentSlideIndex - 1]
        
        return VStack(spacing: 12) {
            // Top row: Author name and stars - bold and no opacity
            HStack {
                Text(currentReview.author)
                    .font(.system(size: 15, weight: .bold)) // Bold and no opacity
                    .foregroundColor(.black)
                
                Spacer()
                
                // Star rating on the right using emoji
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Text("⭐️")
                            .font(.system(size: 14))
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Review text with same horizontal padding as author name - no opacity
            HStack {
                Text(currentReview.text)
                    .font(.system(size: 14))
                    .foregroundColor(.black) // No opacity - pure black
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Simple footer message with dark printer icon
            HStack {
                Image(systemName: "printer.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.6)) // Dark gray instead of blue
                Text("Easy setup and printing")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white, location: 0.0),
                            .init(color: Color.white, location: 0.97),
                            .init(color: Color.gray.opacity(0.05), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
    }

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.15, green: 0.4, blue: 0.8))
                    Text(features[index])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white, location: 0.0),
                            .init(color: Color.white, location: 0.97),
                            .init(color: Color.gray.opacity(0.05), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
    }

    private var trialToggleSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(hasTrialEnabled ? String(localized: "Free Trial Enabled") : String(localized: "Enable Free Trial"))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Toggle("", isOn: $hasTrialEnabled)
                .tint(Color(red: 0.15, green: 0.4, blue: 0.8))
                .scaleEffect(0.9)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        )
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
                            .background(isSelected ? Color(red: 0.15, green: 0.4, blue: 0.8) : Color.gray.opacity(0.4))
                            .cornerRadius(4)
                        Text(subscriptionManager.weeklyPrice(for: product) + String(localized: "/week") )
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.gray)
                    } else if productType == .weeklyTrial {
                        Text("3 DAYS FREE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.15, green: 0.4, blue: 0.8))
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
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.15, green: 0.4, blue: 0.8), lineWidth: 2)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white, location: 0.0),
                                        .init(color: Color.white, location: 0.97),
                                        .init(color: Color.gray.opacity(0.05), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Helper to get title based on product type and trial state
    private func titleForProduct(productType: ProductCardType, hasTrialEnabled: Bool) -> String {
        switch productType {
        case .annual:
            return String(localized: "Yearly Access")
        case .weeklyTrial:
            return String(localized: "First 3 Days Free")
        case .weeklyNoTrial:
            return String(localized: "Weekly Access")
        }
    }

    // Helper to get price string based on product type and trial state
    private func priceStringForProduct(product: Product, productType: ProductCardType, hasTrialEnabled: Bool) -> String {
        let periodSuffix = subscriptionManager.billingPeriodSuffix(for: product)
        switch productType {
        case .annual:
            return product.displayPrice + periodSuffix
        case .weeklyTrial:
            return String(localized: "then") + " " + product.displayPrice + periodSuffix
        case .weeklyNoTrial:
            return product.displayPrice + periodSuffix
        }
    }

    private var purchaseButtonSection: some View {
        VStack(spacing: 12) { // Added more spacing - increased from 8 to 12
            Button { Task { await handlePurchase() } } label: {
                HStack {
                    if subscriptionManager.isLoading { ProgressView().scaleEffect(0.8).tint(.white) }
                    Text(buttonText).font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                }.frame(maxWidth: .infinity).padding(.vertical, 18) // Back to original size
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.6, blue: 0.95),     // Light blue (top)
                            Color(red: 0.15, green: 0.4, blue: 0.8)      // Much darker blue (bottom)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.1, green: 0.3, blue: 0.7).opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                .scaleEffect(buttonBreathingScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { // Faster - reduced from 1.2 to 0.8
                        buttonBreathingScale = 1.05 // More pronounced - increased from 1.03 to 1.05
                    }
                }
            }.disabled(subscriptionManager.isLoading).opacity(subscriptionManager.isLoading ? 0.7 : 1.0)
            
            Group { // Grouping for consistent font and color
                if hasTrialEnabled && selectedProductIndex == 1 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.8, blue: 0.4),  // Light green (top)
                                        Color(red: 0.2, green: 0.6, blue: 0.2)   // Dark green (bottom)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
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
        if hasTrialEnabled && selectedProductIndex == 1 { return String(localized: "Try for Free") }
        else { return String(localized: "Continue") }
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
                        purchaseResultMessage = String(localized: "Purchases restored successfully!")
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
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 3.2, repeats: true) { _ in // Reduced 20% from 4.0 to 3.2
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1)) { // Smoother spring animation
                currentSlideIndex = (currentSlideIndex + 1) % (1 + reviews.count)
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
            purchaseResultMessage = String(localized: "Purchase successful! You now have access to all premium features.")
            showingPurchaseResult = true
        } else {
            if let currentError = subscriptionManager.error {
                if case .userCancelled = currentError {
                } else {
                    purchaseResultMessage = currentError.localizedDescription
                    showingPurchaseResult = true
                }
            } else {
                purchaseResultMessage = String(localized: "An unknown error occurred during purchase.")
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