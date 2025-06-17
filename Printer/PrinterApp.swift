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
    
    var body: some Scene {
        WindowGroup {
            if splashManager.isShowingSplash {
                SplashView()
                    .preferredColorScheme(.light)
                    .environmentObject(splashManager)
                    .background(Color.white.ignoresSafeArea())
                    .onAppear {
                        splashManager.startInitialization()
                    }
            } else if !onboardingManager.hasCompletedOnboarding {
                OnboardingView {
                    onboardingManager.completeOnboarding()
                }
                .preferredColorScheme(.light)
            } else {
                ContentView()
                    .preferredColorScheme(.light)
                    .environmentObject(ScannerManager())
            }
        }
    }
}
