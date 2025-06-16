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
            } else {
                ContentView()
                    .preferredColorScheme(.light)
                    .environmentObject(ScannerManager())
            }
        }
    }
}