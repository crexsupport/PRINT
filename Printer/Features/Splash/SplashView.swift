//
//  SplashView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI
import Lottie

struct SplashView: View {
    @EnvironmentObject var splashManager: SplashManager
    
    var body: some View {
        ZStack {
            // Solid blue background matching reference
            Color(red: 0.2, green: 0.5, blue: 1.0)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Center content area with Lottie animation - smaller size
                LottieView(animation: .named("printer_animation"))
                    .playing(loopMode: .loop)
                    .frame(width: 180, height: 180)
                
                Spacer()
            }
        }
        .onAppear {
            startCleanAnimations()
        }
        .onTapGesture(count: 3) {
            splashManager.skipSplash()
        }
    }
    
    private func startCleanAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                splashManager.isShowingSplash = false
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(SplashManager())
}
