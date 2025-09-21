//
//  SettingsView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import MessageUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var paywallManager: PaywallManager
    @State private var showingMailCompose = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var buttonBreathingScale: Double = 1.0
    
    // PROVISIONAL STATES FOR TESTING UI
    @State private var mockIsSubscribed = false
    @State private var mockHasFreeTrial = true
    
    // Computed properties para el banner premium (usando mock states)
    private var hasFreeTrial: Bool {
        // Disable free trial logic - always false
        return false
    }
    
    private var isSubscribed: Bool {
        return subscriptionManager.isSubscribed
    }
    
    private var primaryProduct: Product? {
        return subscriptionManager.weeklyProduct ?? subscriptionManager.annualProduct
    }
    
    private var bannerTitle: String {
        if isSubscribed {
            return String(localized: "Premium Access")
        } else {
            return String(localized: "Get Premium\nAccess")
        }
    }
    
    private var bannerSubtitle: String {
        if isSubscribed {
            return String(localized: "All features are now available to you")
        } else {
            return String(localized: "Get access to unlimited printing and all templates")
        }
    }
    
    private var bannerButtonText: String {
        if isSubscribed {
            return String(localized: "Manage Subscription")
        } else {
            return String(localized: "Go Premium")
        }
    }
    
    // Helper para extraer días del trial
    private func extractTrialDays(from product: Product) -> String {
        // Buscar información del trial en el producto
        if let introductoryOffer = product.subscription?.introductoryOffer {
            if introductoryOffer.paymentMode == .freeTrial {
                let period = introductoryOffer.period
                switch period.unit {
                case .day:
                    return "\(period.value)"
                case .week:
                    return "\(period.value * 7)"
                default:
                    return "3" // Default fallback
                }
            }
        }
        return "3" // Default fallback
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Premium Card (always visible but changes based on subscription status)
                    premiumCard
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    
                    // Main Settings Section
                    VStack(spacing: 0) {
                        // Manage Subscription (only for premium users)
                        if isSubscribed {
                            settingsRow(
                                icon: "crown.fill",
                                iconColor: .blue,
                                title: String(localized: "Manage Subscription"),
                                showChevron: true
                            ) {
                                // Open App Store subscription management
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Divider().padding(.leading, 60)
                        }
                        
                        // Restore Purchases (only for non-premium users)
                        if !isSubscribed {
                            settingsRow(
                                icon: "arrow.clockwise",
                                iconColor: .blue,
                                title: String(localized: "Restore Purchases"),
                                showChevron: false
                            ) {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                    if subscriptionManager.isSubscribed {
                                        alertMessage = String(localized: "Purchases restored successfully!")
                                        showingAlert = true
                                    } else if let error = subscriptionManager.error {
                                        alertMessage = error.localizedDescription
                                        showingAlert = true
                                    } else {
                                        alertMessage = String(localized: "No previous purchases found.")
                                        showingAlert = true
                                    }
                                }
                            }
                            
                            Divider().padding(.leading, 60)
                        }
                        
                        // Contact Us
                        settingsRow(
                            icon: "message.fill",
                            iconColor: .blue,
                            title: String(localized: "Contact Us"),
                            showChevron: true
                        ) {
                            if MFMailComposeViewController.canSendMail() {
                                showingMailCompose = true
                            } else {
                                alertMessage = String(localized: "Mail is not configured on this device. Please send an email to support@printerapp.com")
                                showingAlert = true
                            }
                        }
                        
                        Divider().padding(.leading, 60)
                        
                        // Share App
                        settingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .blue,
                            title: String(localized: "Share app"),
                            showChevron: true
                        ) {
                            shareApp()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white, location: 0.0),
                                        .init(color: Color.white, location: 0.97),
                                        .init(color: Color.gray.opacity(0.02), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    
                    // Legal Section
                    VStack(spacing: 0) {
                        // Terms of Service
                        settingsRow(
                            icon: "doc.text.fill",
                            iconColor: .brown,
                            title: String(localized: "Terms of Service"),
                            showChevron: true
                        ) {
                            openTermsOfService()
                        }
                        
                        Divider().padding(.leading, 60)
                        
                        // Privacy Policy
                        settingsRow(
                            icon: "hand.raised.fill",
                            iconColor: .brown,
                            title: String(localized: "Privacy Policy"),
                            showChevron: true
                        ) {
                            openPrivacyPolicy()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white, location: 0.0),
                                        .init(color: Color.white, location: 0.97),
                                        .init(color: Color.gray.opacity(0.02), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    
                    // Version Section
                    VStack(spacing: 6) {
                        Text("App Version")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    
                    Spacer().frame(height: 30)
                }
                .padding(.top, 10)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingMailCompose) {
            MailComposeView(
                subject: String(localized: "Printer - Feedback - iOS"),
                body: createEmailBody(),
                recipients: ["support@blastlystudio.com"]
            )
        }
        .alert(String(localized: "Information"), isPresented: $showingAlert) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Premium Card Views
    
    private var premiumCard: some View {
        Group {
            if isSubscribed {
                premiumUserCard
            } else {
                nonPremiumUserCard
            }
        }
    }
    
    private var premiumUserCard: some View {
        VStack(spacing: 0) {
            premiumBadge
            premiumContent
        }
        .background(premiumCardBackground)
    }
    
    private var premiumBadge: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text("PREMIUM")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.green))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var premiumContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(bannerTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.green)
                        .lineSpacing(-8)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(bannerSubtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                premiumPrinterIconLarge
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }
    
    private var premiumPrinterIconLarge: some View {
        ZStack {
            Image("paywall_printerv2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            VStack {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                        .offset(x: -15, y: 10)
                        .zIndex(-2)
                    
                    Spacer()
                    
                    Image(systemName: "photo.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange))
                        .offset(x: 15, y: 5)
                }
                Spacer()
            }
            .frame(width: 120, height: 120)
        }
    }
    
    private var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white, location: 0.0),
                        .init(color: Color.green.opacity(0.05), location: 0.5),
                        .init(color: Color.green.opacity(0.1), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
            .shadow(color: Color.green.opacity(0.1), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
    }
    
    private var nonPremiumUserCard: some View {
        VStack(spacing: 0) {
            nonPremiumContent
            nonPremiumButton
        }
        .background(nonPremiumCardBackground)
    }
    
    private var nonPremiumContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(bannerTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.8))
                        .lineSpacing(-8)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(bannerSubtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                nonPremiumPrinterIcon
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }
    
    private var nonPremiumPrinterIcon: some View {
        ZStack {
            Image("paywall_printerv2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            VStack {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                        .offset(x: -15, y: 10)
                        .zIndex(-2)
                    
                    Spacer()
                    
                    Image(systemName: "photo.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange))
                        .offset(x: 15, y: 5)
                }
                Spacer()
            }
            .frame(width: 120, height: 120)
        }
    }
    
    private var nonPremiumButton: some View {
        Button(action: {
            handlePremiumAction()
        }) {
            Text(bannerButtonText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.6, blue: 0.95),
                            Color(red: 0.15, green: 0.4, blue: 0.8)
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
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        buttonBreathingScale = 1.03
                    }
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    private var nonPremiumCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white, location: 0.0),
                        .init(color: Color.white, location: 0.97),
                        .init(color: Color.blue.opacity(0.02), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
    }
    
    // MARK: - Actions
    
    private func handlePremiumAction() {
        // Always show paywall for non-premium users
        paywallManager.shouldShowPaywall = true
    }
    
    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with square rounded corners and blue gradient - smaller size
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.3, green: 0.6, blue: 0.9),  // Lighter blue
                                    Color(red: 0.2, green: 0.5, blue: 0.8)   // Darker blue
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Subtitle or chevron
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func createEmailBody() -> String {
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        return String(localized: """
        
        
        ---
        Device Information:
        Device: \(deviceModel)
        iOS Version: \(systemVersion)
        App Version: \(appVersion) (\(buildNumber))
        
        Please describe your issue or feedback above this line.
        """)
    }
    
    private func shareApp() {
        let appURL = "https://apps.apple.com/app/printer/id123456789" // Replace with actual App Store URL
        let activityVC = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://printer.addonsmcpe.website/privacy_policy.html") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://printer.addonsmcpe.website/terms_conditions.html") {
            UIApplication.shared.open(url)
        }
    }
}

// Color extension for gold
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// Keep existing supporting structs
struct SettingsItem {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let action: () -> Void
}

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipients: [String]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        mailComposer.setToRecipients(recipients)
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}