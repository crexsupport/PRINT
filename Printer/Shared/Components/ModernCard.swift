//
//  ModernCard.swift
//  Printer
//
//  Created by Pol Nadal Serra on 15/6/25.
//

import SwiftUI

// MARK: - Generic Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let accentColor: Color
    let shadowColor: Color
    
    @State private var isPressed = false
    @State private var animateBackground = false
    
    init(
        backgroundColor: Color = Color(.systemBackground),
        accentColor: Color = .blue,
        shadowColor: Color = .primary,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
        self.shadowColor = shadowColor
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Animated background with mesh gradient effect
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    RadialGradient(
                        colors: [
                            backgroundColor,
                            backgroundColor.opacity(0.8),
                            accentColor.opacity(0.1)
                        ],
                        center: animateBackground ? .topLeading : .bottomTrailing,
                        startRadius: 20,
                        endRadius: animateBackground ? 150 : 100
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.clear,
                                    accentColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.4),
                                    accentColor.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            
            // Content
            content
                .padding(20)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(
            color: shadowColor.opacity(0.15),
            radius: isPressed ? 8 : 12,
            x: 0,
            y: isPressed ? 3 : 6
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateBackground.toggle()
            }
        }
    }
}

// MARK: - Specialized Card Variants
struct HighlightCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var rotateIcon = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            ModernCard(accentColor: color, shadowColor: color) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 70, height: 70)
                            .blur(radius: 8)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(color)
                            .rotationEffect(.degrees(rotateIcon ? 10 : -10))
                            .animation(
                                .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                value: rotateIcon
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            rotateIcon = true
        }
    }
}

// MARK: - Stat Card for showing numbers/progress
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let progress: Double?
    
    @State private var animateProgress = false
    
    var body: some View {
        ModernCard(accentColor: color, shadowColor: color) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let progress = progress {
                        CircularProgressView(progress: animateProgress ? progress : 0, color: color)
                            .frame(width: 30, height: 30)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if let progress = progress {
                    ProgressView(value: animateProgress ? progress : 0)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Circular Progress View Helper
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            HighlightCard(
                title: "Quick Print",
                subtitle: "Print documents instantly",
                icon: "printer.fill",
                color: .blue
            ) {
                print("Quick print tapped")
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Documents",
                    value: "12",
                    icon: "doc.fill",
                    color: .green,
                    progress: 0.7
                )
                
                StatCard(
                    title: "Photos",
                    value: "24",
                    icon: "photo.fill",
                    color: .orange,
                    progress: 0.9
                )
            }
            
            ModernCard(accentColor: .purple) {
                VStack(spacing: 16) {
                    Text("Custom Content")
                        .font(.headline)
                    
                    Text("This card can contain any custom content you want to display beautifully.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}