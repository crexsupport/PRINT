//
//  SplashManager.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI
import Combine

/// Manager for handling splash screen logic and app initialization
class SplashManager: ObservableObject {
    @Published var isShowingSplash = true
    @Published var initializationProgress: Double = 0.0
    @Published var currentLoadingMessage = "Initializing core systems"
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Start the app initialization process
    func startInitialization() {
        performInitializationTasks()
    }
    
    private func performInitializationTasks() {
        let tasks = [
            ("Initializing core systems", 0.12),
            ("Loading security protocols", 0.28),
            ("Establishing network connection", 0.45),
            ("Configuring print drivers", 0.62),
            ("Validating user permissions", 0.78),
            ("Optimizing performance", 0.90),
            ("System ready", 1.0)
        ]
        
        for (index, task) in tasks.enumerated() {
            let delay = Double(index) * 0.6
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentLoadingMessage = task.0
                    self.initializationProgress = task.1
                }
                
                // Complete splash after last task
                if task.1 >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            self.isShowingSplash = false
                        }
                    }
                }
            }
        }
    }
    
    /// Force skip splash screen (for development/testing)
    func skipSplash() {
        withAnimation(.easeInOut(duration: 0.4)) {
            isShowingSplash = false
        }
    }
}
