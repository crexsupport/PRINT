//
//  PrinterApp.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

@main
struct PrinterApp: App {
    @StateObject private var splashManager = SplashManager()
    @StateObject private var onboardingManager = OnboardingManager()
    @StateObject private var paywallManager = PaywallManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    @State private var appState: AppState = .splash
    
    enum AppState {
        case splash
        case onboarding
        case paywall
        case main
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
                        handleOnboardingComplete()
                    }
                    .preferredColorScheme(.light)
                
                case .paywall:
                    PaywallView(onDismiss: {
                        print("Paywall dismissed")
                        paywallManager.markPaywallSeen()
                        appState = .main
                    })
                    .environmentObject(subscriptionManager)
                
                case .main:
                    ContentView()
                        .preferredColorScheme(.light)
                        .environmentObject(ScannerManager())
                        .environmentObject(subscriptionManager)
                        .environmentObject(paywallManager)
                }
            }
            .environmentObject(paywallManager)
            .environmentObject(subscriptionManager)
            .fullScreenCover(isPresented: $paywallManager.shouldShowPaywall) {
                PaywallView(onDismiss: {
                    paywallManager.shouldShowPaywall = false
                })
                .environmentObject(subscriptionManager)
            }
            .onChange(of: subscriptionManager.isSubscribed) { oldValue, newValue in
                if newValue && appState == .paywall {
                    appState = .main
                }
                // Auto-dismiss paywall if user becomes subscribed
                if newValue && paywallManager.shouldShowPaywall {
                    paywallManager.shouldShowPaywall = false
                }
            }
        }
    }
    
    private func handleSplashComplete() {
        if onboardingManager.hasCompletedOnboarding {
            // Usuario que regresa
            if subscriptionManager.isSubscribed {
                // Ya es premium, ir directo a main
                appState = .main
            } else {
                // No es premium, mostrar paywall
                appState = .paywall
            }
        } else {
            // Primera vez, mostrar onboarding
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
