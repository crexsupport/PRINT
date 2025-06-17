import SwiftUI

struct HelpTipView: View {
    @State private var currentTipIndex = 0
    @State private var timer: Timer?
    @State private var isPressed = false
    @State private var showGlow = false
    @State private var swipeDirection: SwipeDirection = .none

    private let tips = [
        HelpTip(
            title: "Wi-Fi Connection Required",
            description: "Make sure your printer and device are connected to the same Wi-Fi network for best results.",
            icon: "wifi",
            color: .blue,
            gradient: [Color.blue, Color.cyan]
        ),
        HelpTip(
            title: "Scan Multiple Pages",
            description: "Tap and hold the scan button to activate batch scanning mode for multiple documents.",
            icon: "camera.viewfinder",
            color: .green,
            gradient: [Color.green, Color.mint]
        ),
        HelpTip(
            title: "Save Paper",
            description: "Use the preview feature to check your document before printing to avoid waste.",
            icon: "leaf.fill",
            color: .green,
            gradient: [Color.green, Color.yellow]
        ),
        HelpTip(
            title: "Print Quality",
            description: "Adjust print quality settings in each feature to optimize for your specific needs.",
            icon: "slider.horizontal.3",
            color: .purple,
            gradient: [Color.purple, Color.pink]
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(showGlow ? 0.3 : 0.1),
                                    Color.orange.opacity(showGlow ? 0.2 : 0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 32, height: 32)
                        .scaleEffect(showGlow ? 1.2 : 1.0)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.3), radius: 4)
                }

                Text("Helpful Tips")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                InnovativeHelpTipIndicator(
                    currentIndex: currentTipIndex,
                    totalCount: tips.count
                )
            }
            .padding(.horizontal)

            ModernTipCard(tip: tips[currentTipIndex], isPressed: $isPressed)
                .padding(.horizontal)
                .transition(.asymmetric(
                    insertion: swipeDirection == .right ? 
                        .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.95)) :
                        .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                    removal: swipeDirection == .right ?
                        .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 1.05)) :
                        .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 1.05))
                ))
                .id(currentTipIndex)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            // Reset timer when user swipes manually
                            stopAutoRotation()
                            startAutoRotation()
                            
                            if value.translation.width > 50 {
                                // Swipe right - go to previous tip (backward)
                                swipeDirection = .right
                                previousTip()
                            } else if value.translation.width < -50 {
                                // Swipe left - go to next tip (forward)
                                swipeDirection = .left
                                nextTip()
                            }
                        }
                )
        }
        .onAppear {
            startAutoRotation()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                showGlow = true
            }
        }
        .onDisappear {
            stopAutoRotation()
        }
    }

    private func startAutoRotation() {
        timer?.invalidate() // Clear any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            // Auto-rotation always goes forward (left direction)
            swipeDirection = .left
            nextTip()
        }
    }

    private func stopAutoRotation() {
        timer?.invalidate()
        timer = nil
    }

    private func nextTip() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentTipIndex = (currentTipIndex + 1) % tips.count
        }
        
        // Reset direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            swipeDirection = .none
        }
    }
    
    private func previousTip() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentTipIndex = (currentTipIndex - 1 + tips.count) % tips.count
        }
        
        // Reset direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            swipeDirection = .none
        }
    }
}

// Add enum for swipe direction
enum SwipeDirection {
    case left, right, none
}

struct InnovativeHelpTipIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(currentIndex + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                )
                .scaleEffect(1.1)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentIndex)
            
            Text("of")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(totalCount)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 24, height: 3)
                
                Capsule()
                    .fill(Color.primary)
                    .frame(
                        width: 24 * CGFloat(currentIndex + 1) / CGFloat(totalCount),
                        height: 3
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct HelpTip {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let gradient: [Color]
}

struct ModernTipCard: View {
    let tip: HelpTip
    @Binding var isPressed: Bool
    @State private var animateIcon = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    tip.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            tip.color.opacity(0.05),
                            tip.gradient[1].opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    tip.color.opacity(0.2),
                                    tip.color.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 56, height: 56)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: tip.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: tip.color.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: tip.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                        .rotationEffect(.degrees(animateIcon ? 5 : -5))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(tip.title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.primary)
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : 20)

                    Text(tip.description)
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : 30)
                }

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(tip.color.opacity(0.4))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(tip.color.opacity(0.4))
                }
                .opacity(showContent ? 0.6 : 0)
                .scaleEffect(isPressed ? 1.2 : 1.0)
            }
            .padding(16)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }

            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
    }
}

#Preview {
    HelpTipView()
        .padding()
        .background(Color(.systemGroupedBackground))
}
