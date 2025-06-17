import SwiftUI

struct WelcomeBannerView: View {
    let onDismiss: () -> Void
    @State private var animatePrinter = false
    @State private var animateGradient = false
    @State private var showContent = false
    @State private var swipeOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDismissing = false
    
    var body: some View {
        ZStack {
            // Simple animated gradient background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.6),
                            Color.purple.opacity(0.4),
                            Color.cyan.opacity(0.5),
                            Color.indigo.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Glassmorphism overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Main content - REDUCIDO padding y spacing
            VStack(spacing: 12) { // REDUCIDO de 18 a 12
                // Header with icon and title
                HStack(alignment: .top, spacing: 12) { // REDUCIDO de 16 a 12
                    VStack(alignment: .leading, spacing: 6) { // REDUCIDO de 10 a 6
                        HStack(spacing: 6) { // REDUCIDO de 8 a 6
                            // Sparkles icon
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .medium)) // REDUCIDO de 18 a 16
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .yellow.opacity(0.4), radius: 3)
                            
                            Text("Welcome to\nSmart Printer")
                                .font(.system(.headline, design: .default, weight: .bold)) // REDUCIDO de title3 a headline
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .primary.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .lineLimit(2)
                        }
                        
                        Text("Everything you need to print, scan, and manage documents in one powerful app")
                            .font(.system(.caption, design: .default)) // REDUCIDO de subheadline a caption
                            .foregroundColor(.secondary)
                            .lineLimit(2) // REDUCIDO de 3 a 2
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Simple printer icon - REDUCIDO
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40) // REDUCIDO de 50 a 40
                        
                        Image(systemName: "printer.filled.and.paper")
                            .font(.system(size: 20, weight: .medium)) // REDUCIDO de 24 a 20
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.25), radius: 6)
                    }
                }
                
                // Feature highlights - REDUCIDOS
                HStack(spacing: 16) { // REDUCIDO de 20 a 16
                    FeatureHighlight(icon: "doc.text.fill", title: "Scan", color: .green)
                    FeatureHighlight(icon: "printer.fill", title: "Print", color: .blue)
                    FeatureHighlight(icon: "doc.on.doc.fill", title: "Manage", color: .purple)
                    FeatureHighlight(icon: "square.and.arrow.up.fill", title: "Share", color: .orange)
                }
                .opacity(showContent ? 1 : 0)
                
                // COMMENTED: Simple swipe indicator
                /*
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(dragOffset < -5 ? 0.6 : 0.3))
                        .frame(width: dragOffset < -5 ? 44 : 36, height: 4)
                    
                    Text("Swipe up to dismiss")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(.secondary.opacity(dragOffset < -5 ? 0.8 : 0.5))
                }
                .opacity(showContent ? 1 : 0)
                .padding(.top, 8)
                */
            }
            .padding(.horizontal, 18) // REDUCIDO de 20 a 18
            .padding(.vertical, 14) // REDUCIDO de 18 a 14
        }
        .offset(y: swipeOffset)
        .scaleEffect(showContent && !isDismissing ? 1 : 0.95)
        .opacity(showContent && !isDismissing ? 1 : 0)
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        
        // COMMENTED: Gesture for dismiss functionality
        /*
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    if !isDismissing {
                        dragOffset = value.translation.height
                        if value.translation.height < 0 {
                            swipeOffset = value.translation.height * 0.4
                        }
                    }
                }
                .onEnded { value in
                    if !isDismissing && value.translation.height < -50 {
                        isDismissing = true
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.easeOut(duration: 0.35)) {
                            swipeOffset = -400
                            showContent = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onDismiss()
                        }
                    } else if !isDismissing {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            swipeOffset = 0
                            dragOffset = 0
                        }
                    }
                }
        )
        */
        
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
}

// Simple FeatureHighlight component - REDUCIDO
struct FeatureHighlight: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) { // REDUCIDO de 5 a 4
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28) // REDUCIDO de 32 a 28
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium)) // REDUCIDO de 14 a 12
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(.caption2, design: .default, weight: .medium)) // REDUCIDO de caption a caption2
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WelcomeBannerView(onDismiss: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}
