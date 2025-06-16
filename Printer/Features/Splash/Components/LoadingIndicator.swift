//
//  LoadingIndicator.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

struct LoadingIndicator: View {
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            ProgressBarView(progress: progress)
                .frame(width: 220, height: 8)
            
            // Loading message
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .animation(.easeInOut(duration: 0.3), value: message)
        }
    }
}

struct ProgressBarView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow,
                                Color.orange,
                                Color.yellow
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Shimmer effect
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.6),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 30)
                        .offset(x: -15 + (geometry.size.width * progress * 0.8))
                        .animation(
                            Animation.linear(duration: 1.0)
                                .repeatForever(autoreverses: false),
                            value: progress
                        )
                        .clipped()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        VStack {
            LoadingIndicator(progress: 0.7, message: "Loading preferences...")
            LoadingIndicator(progress: 0.3, message: "Connecting to services...")
        }
    }
}