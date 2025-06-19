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
    @State private var shimmerOffset: CGFloat = 0
    @State private var animationTrigger = false
    @State private var showingMailCompose = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Modern header with glassmorphism
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Customize your printing experience")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 32)
                    
                    VStack(spacing: 28) {
                        // Premium Card (only for non-premium users)
                        if !subscriptionManager.isSubscribed {
                            premiumUpgradeCard
                                .padding(.horizontal, 20)
                        }
                        
                        // Support Section with modern design
                        modernSettingsSection(title: "SUPPORT", items: supportItems, iconColor: .blue)
                        
                        // About Section with modern design
                        modernSettingsSection(title: "ABOUT", items: aboutItems, iconColor: .blue)
                        
                        // Modern app version card
                        modernVersionCard
                            .padding(.horizontal, 20)
                    }
                    
                    // Bottom spacing
                    Spacer().frame(height: 80)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.systemGroupedBackground).opacity(0.8),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingMailCompose) {
            MailComposeView(
                subject: "Printer - Feedback - iOS",
                body: createEmailBody(),
                recipients: ["support@blastlystudio.com"]
            )
        }
        .alert("Information", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            animationTrigger = true
        }
    }
    
    private var premiumUpgradeCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Printer icon with glassmorphism effect (matching app theme)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .blur(radius: 0.5)
                    
                    Image(systemName: "printer.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Go Premium")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Unlock unlimited printing & premium features")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Floating arrow with glow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 2)
                    .scaleEffect(animationTrigger ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animationTrigger)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                // Main gradient background (matching app's blue theme)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.9),
                                Color.blue.opacity(0.7),
                                Color.cyan.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glassmorphism overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear,
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle border glow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
        .shadow(color: Color.blue.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                paywallManager.shouldShowPaywall = true
            }
        }
        .onAppear {
            animationTrigger = true
        }
    }
    
    private func modernSettingsSection(title: String, items: [SettingsItem], iconColor: Color) -> some View {
        VStack(spacing: 16) {
            // Modern section header
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Modern cards container
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ModernSettingsRow(item: item, iconColor: iconColor)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var modernVersionCard: some View {
        VStack(spacing: 6) {
            Text("Printer Pro")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.vertical, 20)
    }

    private var supportItems: [SettingsItem] {
        [
            SettingsItem(
                id: "restore",
                title: "Restore Purchases",
                subtitle: "Sync your premium features",
                icon: "arrow.clockwise",
                iconColor: .blue,
                action: {
                    Task {
                        await subscriptionManager.restorePurchases()
                        if subscriptionManager.isSubscribed {
                            alertMessage = "Purchases restored successfully!"
                            showingAlert = true
                        } else if let error = subscriptionManager.error {
                            alertMessage = error.localizedDescription
                            showingAlert = true
                        } else {
                            alertMessage = "No previous purchases found."
                            showingAlert = true
                        }
                    }
                }
            ),
            SettingsItem(
                id: "contact",
                title: "Contact Support",
                subtitle: "Get help from our team",
                icon: "envelope",
                iconColor: .blue,
                action: {
                    if MFMailComposeViewController.canSendMail() {
                        showingMailCompose = true
                    } else {
                        alertMessage = "Mail is not configured on this device. Please send an email to support@printerapp.com"
                        showingAlert = true
                    }
                }
            )
        ]
    }
    
    private var aboutItems: [SettingsItem] {
        [
            SettingsItem(
                id: "privacy",
                title: "Privacy Policy",
                subtitle: "How we protect your data",
                icon: "hand.raised",
                iconColor: .blue,
                action: { openPrivacyPolicy() }
            ),
            SettingsItem(
                id: "terms",
                title: "Terms of Service",
                subtitle: "Our terms and conditions",
                icon: "doc.text",
                iconColor: .blue,
                action: { openTermsOfService() }
            )
        ]
    }

    private func createEmailBody() -> String {
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        return """
        
        
        ---
        Device Information:
        Device: \(deviceModel)
        iOS Version: \(systemVersion)
        App Version: \(appVersion) (\(buildNumber))
        
        Please describe your issue or feedback above this line.
        """
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

struct SettingsItem {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let action: () -> Void
}

struct ModernSettingsRow: View {
    let item: SettingsItem
    let iconColor: Color
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            item.action()
        }) {
            HStack(spacing: 16) {
                // Modern icon with glassmorphism
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    iconColor.opacity(0.15),
                                    iconColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                        .shadow(color: iconColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                // Modern arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear,
                                    iconColor.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(iconColor.opacity(0.1), lineWidth: 1)
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
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
