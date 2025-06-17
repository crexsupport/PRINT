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
    @State private var isUserPremium = false // Simulated premium status
    @State private var shimmerOffset: CGFloat = 0
    @State private var animationTrigger = false
    @State private var showingMailCompose = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with better spacing
                    VStack(spacing: 8) {
                        HStack {
                            Text("Settings")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 24) {
                        // Premium Card (only for non-premium users)
                        if !isUserPremium {
                            premiumUpgradeCard
                                .padding(.horizontal, 20)
                        }
                        
                        // Support Section
                        settingsSection(title: "SUPPORT", items: supportItems)
                        
                        // About Section
                        settingsSection(title: "ABOUT", items: aboutItems)
                        
                        // App Version with better styling
                        VStack(spacing: 6) {
                            Text("Printer Pro")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
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
            startShimmerAnimation()
        }
        .onChange(of: animationTrigger) { _ in
            // Restart animation when trigger changes
        }
    }
    
    private var premiumUpgradeCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Crown without background circle
                Image(systemName: "crown.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 8, x: 0, y: 4)
                    .scaleEffect(1.1)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Upgrade to Premium")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Unlock all features and remove ads")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                // Solid blue gradient background (only blues)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0),
                                Color(red: 0.1, green: 0.5, blue: 0.95),
                                Color(red: 0.0, green: 0.4, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Inner border glow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.blue.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.blue.opacity(0.4), radius: 25, x: 0, y: 12)
        .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 4)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                // Handle premium upgrade with haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                print("Premium upgrade tapped")
            }
        }
    }
    
    private func startShimmerAnimation() {
        // Shimmer removed - this function is no longer needed but keeping for compatibility
    }
    
    private func settingsSection(title: String, items: [SettingsItem]) -> some View {
        VStack(spacing: 0) {
            // Section header with better spacing
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            // Section items with enhanced styling
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    SettingsRow(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
        }
    }

    private var supportItems: [SettingsItem] {
        [
            SettingsItem(
                id: "restore",
                title: "Restore Purchases",
                subtitle: nil,
                icon: "arrow.clockwise",
                iconColor: .blue,
                action: { restorePurchases() }
            ),
            SettingsItem(
                id: "contact",
                title: "Contact Support",
                subtitle: nil,
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
                subtitle: nil,
                icon: "doc.text",
                iconColor: .blue,
                action: { openPrivacyPolicy() }
            ),
            SettingsItem(
                id: "terms",
                title: "Terms of Service",
                subtitle: nil,
                icon: "lock",
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
    
    private func restorePurchases() {

    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://printerapp.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://printerapp.com/terms") {
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

struct SettingsRow: View {
    let item: SettingsItem
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            item.action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(item.iconColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPressed ? Color(.systemGray6) : Color.clear)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
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
}
