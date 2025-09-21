//
//  HomeView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showWelcomeBanner = true
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var paywallManager: PaywallManager

    var body: some View {
        NavigationView {
            ZStack {
                // Much closer to original white background
                Color.white
                    .ignoresSafeArea()
                
                // Main scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Adjusted top padding for header with bottom padding
                        Spacer()
                            .frame(height: 45) // Reduced from 56 to 40
                        
                        // Welcome banner immediately after header
                        if showWelcomeBanner {
                            WelcomeBannerView(onDismiss: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showWelcomeBanner = false
                                }
                            })
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            ))
                            
                            // Spacing after welcome banner - REDUCIDO
                            Spacer()
                                .frame(height: 16)
                        } else {
                            // Extra spacing when banner is dismissed - REDUCIDO
                            Spacer()
                                .frame(height: 12)
                        }
                        
                        // HelpTipView - with proper spacing
                        HelpTipView()
                        
                        // Spacing before features - REDUCIDO
                        Spacer()
                            .frame(height: 16)
                        
                        // Features section con título y grid
                        FeaturesSection()
                        
                        Spacer(minLength: 20) // REDUCIDO de 30 a 20
                    }
                    .animation(.easeInOut(duration: 0.4), value: showWelcomeBanner)
                }
                .refreshable {
                    // Pull to refresh functionality
                    await refreshData()
                }
                
                // Fixed header with white background and bottom padding
                VStack(spacing: 0) {
                    // Header content with white background
                    VStack(spacing: 0) {
                        // Safe area background extension - WHITE
                        Rectangle()
                            .fill(Color.white)
                            .ignoresSafeArea(.all, edges: .top)
                            .frame(height: 0)
                        
                        // Main header content - WHITE BACKGROUND with bottom padding
                        HStack {
                            if !subscriptionManager.isSubscribed {
                                Button(action: {
                                    paywallManager.shouldShowPaywall = true
                                }) {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 18))
                                }
                            }
                            
                            Spacer()
                            
                            Text("Smart Printer")
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("+")
                                .font(.system(size: 18, weight: .light))
                            
                            Spacer()
                            
//                            Button(action: {
//                                // Help action
//                            }) {
//                                HStack(spacing: 4) {
//                                    Image(systemName: "questionmark.circle")
//                                        .font(.system(size: 15))
//                                    Text("Help")
//                                        .font(.system(size: 15))
//                                }
//                                .foregroundColor(.blue)
//                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 0)
                        .padding(.bottom, 12) // Added bottom padding - increased from 4 to 12
                        .background(Color.white) // WHITE BACKGROUND
                    }
                    .background(
                        // Full white background that extends to safe area
                        Rectangle()
                            .fill(Color.white)
                            .ignoresSafeArea(.all, edges: .top)
                    )
                    .overlay(
                        // Bottom border line
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 0.5),
                        alignment: .bottom
                    )
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func refreshData() async {
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

#Preview {
    HomeView()
        .environmentObject(ScannerManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}
