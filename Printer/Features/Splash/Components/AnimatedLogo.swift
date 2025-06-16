//
//  AnimatedLogo.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

struct AnimatedLogo: View {
    @State private var isAnimating = false
    @State private var shadowRadius: CGFloat = 5
    @State private var iconScale: CGFloat = 1.0
    
    let size: CGFloat
    
    init(size: CGFloat = 100) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle shadow
            Circle()
                .fill(Color.white)
                .frame(width: size * 1.2, height: size * 1.2)
                .shadow(
                    color: .black.opacity(0.08),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowRadius / 2
                )
                .animation(
                    Animation.easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true),
                    value: shadowRadius
                )
            
            // Inner circle with border
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .fill(Color(.systemGray6).opacity(0.1))
                .frame(width: size, height: size)
            
            // Printer icon
            Image(systemName: "printer.fill")
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(.black)
                .scaleEffect(iconScale)
                .animation(
                    Animation.easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true),
                    value: iconScale
                )
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Shadow pulsing animation
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            shadowRadius = 15
        }
        
        // Icon subtle scale animation
        withAnimation(
            Animation.easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
        ) {
            iconScale = 1.05
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGray6).ignoresSafeArea()
        AnimatedLogo()
    }
}
