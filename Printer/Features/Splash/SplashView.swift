//
//  SplashView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var splashManager: SplashManager
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.9
    @State private var contentOpacity: Double = 0.0
    @State private var brandOpacity: Double = 0.0
    @State private var progressOpacity: Double = 0.0
    @State private var backgroundShift: Double = 0.0
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            AngularGradient(
                colors: [
                    Color(.systemGray6),
                    Color.white,
                    Color(.systemGray5),
                    Color.white,
                    Color(.systemGray6)
                ],
                center: .center,
                angle: .degrees(backgroundShift)
            )
            .ignoresSafeArea()
            .animation(
                Animation.linear(duration: 20.0)
                    .repeatForever(autoreverses: false),
                value: backgroundShift
            )
            
            // Subtle overlay pattern
            ModernPatternOverlay()
                .opacity(0.03)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content area
                VStack(spacing: 40) {
                    // Company logo section
                    VStack(spacing: 20) {
                        // Modern logo container
                        ModernLogoContainer()
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                        
                        // Brand identity
                        VStack(spacing: 8) {
                            HStack(spacing: 0) {
                                Text("SMART")
                                    .font(.system(size: 28, weight: .ultraLight, design: .default))
                                    .foregroundColor(.black)
                                    .tracking(4.0)
                                
                                Text("PRINTER")
                                    .font(.system(size: 28, weight: .medium, design: .default))
                                    .foregroundColor(.black)
                                    .tracking(2.0)
                            }
                            
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 60, height: 1)
                            
                            Text("ENTERPRISE SOLUTIONS")
                                .font(.system(size: 11, weight: .regular, design: .default))
                                .foregroundColor(.gray)
                                .tracking(1.5)
                        }
                        .opacity(brandOpacity)
                    }
                    
                    // Status section
                    VStack(spacing: 25) {
                        SystemStatusIndicator()
                            .opacity(contentOpacity)
                        
                        ModernProgressIndicator(
                            progress: splashManager.initializationProgress,
                            message: splashManager.currentLoadingMessage
                        )
                        .opacity(progressOpacity)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("© 2025 Smart Printer")
                        .font(.system(size: 10, weight: .regular, design: .default))
                        .foregroundColor(.gray.opacity(0.7))
                        .tracking(0.5)
                    
                    Text("Version 1.0")
                        .font(.system(size: 9, weight: .light, design: .default))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .opacity(contentOpacity)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startCorporateAnimations()
        }
        .onTapGesture(count: 3) {
            // Triple tap to skip (more discrete)
            splashManager.skipSplash()
        }
    }
    
    private func startCorporateAnimations() {
        // Background rotation
        withAnimation {
            backgroundShift = 360
        }
        
        // Logo entrance
        withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        
        // Brand reveal
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
            brandOpacity = 1.0
        }
        
        // System status
        withAnimation(.easeOut(duration: 0.6).delay(1.5)) {
            contentOpacity = 1.0
        }
        
        // Progress indicator
        withAnimation(.easeOut(duration: 0.5).delay(2.0)) {
            progressOpacity = 1.0
        }
    }
}

struct ModernLogoContainer: View {
    @State private var innerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var iconOpacity: Double = 0.9
    
    var body: some View {
        ZStack {
            // Simple professional container
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
            
            // Printer image filling the entire container
            Image("printer_splash")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(iconOpacity)
                .scaleEffect(pulseScale)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .animation(
                    Animation.easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true),
                    value: iconOpacity
                )
        }
        .onAppear {
            innerRotation = 360
            pulseScale = 1.02
            iconOpacity = 1.0
        }
    }
}

struct SystemStatusIndicator: View {
    @State private var statusIndex = 0
    private let statusItems = ["SYSTEM", "NETWORK", "DRIVERS", "READY"]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { index in
                VStack(spacing: 6) {
                    Circle()
                        .fill(index <= statusIndex ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Text(statusItems[index])
                        .font(.system(size: 8, weight: .medium, design: .default))
                        .foregroundColor(index <= statusIndex ? .black : .gray)
                        .tracking(0.5)
                }
                .opacity(index <= statusIndex ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.3), value: statusIndex)
            }
        }
        .onAppear {
            animateStatus()
        }
    }
    
    private func animateStatus() {
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    statusIndex = i
                }
            }
        }
    }
}

struct ModernProgressIndicator: View {
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 18) {
            // Simple professional progress dots
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(Double(index) / 5.0 <= progress ? Color.black : Color.gray.opacity(0.25))
                        .frame(width: 6, height: 6)
                        .scaleEffect(Double(index) / 5.0 <= progress ? 1.0 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.4)
                            .delay(Double(index) * 0.1),
                            value: progress
                        )
                }
            }
            
            // Status message
            Text(message.uppercased())
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundColor(.black.opacity(0.6))
                .tracking(1.0)
                .animation(.easeInOut(duration: 0.3), value: message)
        }
    }
}

struct ModernPatternOverlay: View {
    var body: some View {
        ZStack {
            // Dot pattern
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 15), spacing: 30) {
                ForEach(0..<150, id: \.self) { _ in
                    Circle()
                        .fill(Color.black)
                        .frame(width: 1, height: 1)
                }
            }
            
            // Diagonal lines
            Path { path in
                let spacing: CGFloat = 60
                let width = UIScreen.main.bounds.width * 1.5
                let height = UIScreen.main.bounds.height * 1.5
                
                for i in stride(from: -width, through: width * 2, by: spacing) {
                    path.move(to: CGPoint(x: i, y: -height))
                    path.addLine(to: CGPoint(x: i + height, y: height * 2))
                }
            }
            .stroke(Color.black.opacity(0.02), lineWidth: 0.5)
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(SplashManager())
}
