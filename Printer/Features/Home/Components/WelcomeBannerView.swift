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
            // Estilo de relieve como en PaywallView
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white, location: 0.0),
                            .init(color: Color.white, location: 0.97),
                            .init(color: Color.gray.opacity(0.05), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
            
            // Overlay colorido sutil sobre el fondo de relieve
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.08),
                            Color.purple.opacity(0.05),
                            Color.cyan.opacity(0.06),
                            Color.indigo.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Main content - REDUCIDO padding y spacing
            VStack(spacing: 10) { // REDUCIDO de 12 a 10
                // Header with icon and title
                HStack(alignment: .top, spacing: 10) { // REDUCIDO de 12 a 10
                    VStack(alignment: .leading, spacing: 4) { // REDUCIDO de 6 a 4
                        HStack(spacing: 6) { // REDUCIDO de 6 a 6
                            // Sparkles icon
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium)) // REDUCIDO de 16 a 14
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .yellow.opacity(0.4), radius: 3)
                            
                            Text(String(localized: "Welcome to\nSmart Printer"))
                                .font(.system(.subheadline, design: .default, weight: .bold)) // REDUCIDO de headline a subheadline
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .primary.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .lineLimit(2)
                        }
                        
                        HStack(spacing: 6) {
                            // Spacer invisible del mismo tamaño que el icono sparkles
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                                .opacity(0) // Invisible pero ocupa el mismo espacio
                            
                            Text(String(localized: "Everything you need to print, scan, and manage documents in one powerful app"))
                                .font(.system(.caption, design: .default)) // Cambiado de size 11 de vuelta a .caption
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                    
                    // Simple printer icon - REDUCIDO
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 36, height: 36) // REDUCIDO de 40 a 36
                        
                        Image(systemName: "printer.filled.and.paper")
                            .font(.system(size: 18, weight: .medium)) // REDUCIDO de 20 a 18
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
                HStack(spacing: 14) { // REDUCIDO de 16 a 14
                    FeatureHighlight(icon: "doc.text.fill", title: String(localized: "Scan"), color: .green)
                    FeatureHighlight(icon: "printer.fill", title: String(localized: "Print"), color: .blue)
                    FeatureHighlight(icon: "doc.on.doc.fill", title: String(localized: "Manage"), color: .purple)
                    FeatureHighlight(icon: "square.and.arrow.up.fill", title: String(localized: "Share"), color: .orange)
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
            .padding(.horizontal, 16) // REDUCIDO de 18 a 16
            .padding(.vertical, 12) // REDUCIDO de 14 a 12
        }
        .offset(y: swipeOffset)
        .scaleEffect(showContent && !isDismissing ? 1 : 0.95)
        .opacity(showContent && !isDismissing ? 1 : 0)
        
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
        VStack(spacing: 3) { // REDUCIDO de 4 a 3
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 26, height: 26) // REDUCIDO de 28 a 26
                
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium)) // REDUCIDO de 12 a 11
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium)) // REDUCIDO usando tamaño específico
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WelcomeBannerView(onDismiss: {})
        .padding()
        .background(Color.white)
}