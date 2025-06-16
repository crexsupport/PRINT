//
//  SplashView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var splashManager: SplashManager
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 50
    @State private var titleOpacity: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var particlesVisible = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.blue,
                    Color.indigo
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background particles
            ParticleBackground(isVisible: particlesVisible)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo section
                VStack(spacing: 20) {
                    AnimatedLogo(size: 120)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // App title
                    VStack(spacing: 8) {
                        Text("Smart Printer")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Pro")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                }
                
                Spacer()
                
                // Loading section
                LoadingIndicator(
                    progress: splashManager.initializationProgress,
                    message: splashManager.currentLoadingMessage
                )
                .opacity(contentOpacity)
                .padding(.bottom, 80)
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
        .onTapGesture(count: 2) {
            // Double tap to skip splash (for development)
            splashManager.skipSplash()
        }
    }
    
    private func startAnimations() {
        // Particles
        withAnimation(.easeIn(duration: 0.5)) {
            particlesVisible = true
        }
        
        // Logo animation
        withAnimation(.easeOut(duration: 1.0)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        // Content animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.6)) {
                contentOpacity = 1.0
            }
        }
    }
}

struct ParticleBackground: View {
    let isVisible: Bool
    
    var body: some View {
        ForEach(0..<15, id: \.self) { index in
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: CGFloat.random(in: 4...12))
                .position(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                )
                .opacity(isVisible ? 1 : 0)
                .animation(
                    Animation.easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                    value: isVisible
                )
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(SplashManager())
}