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
        VStack(spacing: 20) {
            // Progress bar
            ProgressBarView(progress: progress)
                .frame(width: 250, height: 4)
            
            // Loading message
            Text(message)
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundColor(.gray)
                .tracking(0.3)
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
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                
                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Subtle highlight effect
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 20)
                        .offset(x: (geometry.size.width * progress) - 10)
                        .animation(
                            Animation.linear(duration: 1.5)
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
        Color.white.ignoresSafeArea()
        VStack(spacing: 30) {
            LoadingIndicator(progress: 0.3, message: "Initializing system...")
            LoadingIndicator(progress: 0.7, message: "Loading preferences...")
            LoadingIndicator(progress: 1.0, message: "Ready!")
        }
    }
}
