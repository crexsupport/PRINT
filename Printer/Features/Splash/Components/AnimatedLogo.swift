//
//  AnimatedLogo.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

struct AnimatedLogo: View {
    @State private var isAnimating = false
    @State private var glowIntensity: Double = 0.5
    
    let size: CGFloat
    
    init(size: CGFloat = 120) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Glow effect background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(glowIntensity * 0.6),
                            Color.orange.opacity(glowIntensity * 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.25,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size, height: size)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: glowIntensity
                )
            
            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.8), radius: 15, x: 0, y: 0)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .animation(
                    Animation.easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation {
            isAnimating = true
        }
        
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 1.0
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        AnimatedLogo()
    }
}