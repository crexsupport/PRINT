//
//  OnboardingManager.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    
    private let userDefaultsKey = "hasCompletedOnboarding"
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: userDefaultsKey)
    }
}