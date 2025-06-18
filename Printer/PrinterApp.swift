//
//  PrinterApp.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import FirebaseCore

@main
struct PrinterApp: App {
    @StateObject private var splashManager = SplashManager()
    @StateObject private var onboardingManager = OnboardingManager()
    @StateObject private var paywallManager = PaywallManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var attManager = ATTManager()
    
    @State private var appState: AppState = .splash
    
    enum AppState {
        case splash
        case onboarding
        case paywall
        case main
    }
    
    init() {
        FirebaseApp.configure()
        
        // Track app launch (this is allowed even without ATT permission)
        AnalyticsManager.shared.trackAppLaunch(isFirstLaunch: !OnboardingManager().hasCompletedOnboarding)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case .splash:
                    SplashView()
                        .preferredColorScheme(.light)
                        .environmentObject(splashManager)
                        .background(Color.white.ignoresSafeArea())
                        .onAppear {
                            splashManager.startInitialization()
                        }
                        .onChange(of: splashManager.isShowingSplash) { oldValue, newValue in
                            if !newValue {
                                handleSplashComplete()
                            }
                        }
                
                case .onboarding:
                    OnboardingView {
                        onboardingManager.completeOnboarding()
                        AnalyticsManager.shared.trackOnboardingCompleted()
                        handleOnboardingComplete()
                    }
                    .preferredColorScheme(.light)
                    .environmentObject(attManager)
                
                case .paywall:
                    PaywallView(onDismiss: {
                        print("Paywall dismissed")
                        paywallManager.markPaywallSeen()
                        AnalyticsManager.shared.trackPaywallDismissed(context: "after_onboarding")
                        appState = .main
                    })
                    .environmentObject(subscriptionManager)
                    .onAppear {
                        AnalyticsManager.shared.trackPaywallView(context: "after_onboarding")
                    }
                
                case .main:
                    ContentView()
                        .preferredColorScheme(.light)
                        .environmentObject(ScannerManager())
                        .environmentObject(subscriptionManager)
                        .environmentObject(paywallManager)
                        .environmentObject(attManager)
                }
            }
            .environmentObject(paywallManager)
            .environmentObject(subscriptionManager)
            .environmentObject(attManager)
            .fullScreenCover(isPresented: $paywallManager.shouldShowPaywall) {
                PaywallView(onDismiss: {
                    paywallManager.shouldShowPaywall = false
                    AnalyticsManager.shared.trackPaywallDismissed(context: "feature_restricted")
                })
                .environmentObject(subscriptionManager)
                .onAppear {
                    AnalyticsManager.shared.trackPaywallView(context: "feature_restricted")
                }
            }
            .onChange(of: subscriptionManager.isSubscribed) { oldValue, newValue in
                if newValue && appState == .paywall {
                    appState = .main
                }
                // Auto-dismiss paywall if user becomes subscribed
                if newValue && paywallManager.shouldShowPaywall {
                    paywallManager.shouldShowPaywall = false
                }
                
                if oldValue != newValue {
                    AnalyticsManager.shared.setUserSubscriptionStatus(isSubscribed: newValue)
                }
            }
        }
    }
    
    private func handleSplashComplete() {
        if onboardingManager.hasCompletedOnboarding {
            // Usuario que regresa - check ATT status
            Task {
                await attManager.checkCurrentStatus()
            }
            
            if subscriptionManager.isSubscribed {
                // Ya es premium, ir directo a main
                appState = .main
            } else {
                // No es premium, mostrar paywall
                appState = .paywall
            }
        } else {
            // Primera vez, mostrar onboarding (ATT se maneja dentro del onboarding)
            appState = .onboarding
        }
    }
    
    private func handleOnboardingComplete() {
        if subscriptionManager.isSubscribed {
            // Ya es premium (caso raro), ir directo a main
            appState = .main
        } else {
            // No es premium, mostrar paywall
            appState = .paywall
        }
    }
}
