import SwiftUI

struct RemoveBackgroundProcessingView: View {
    @ObservedObject var viewModel: RemoveBackgroundViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Processing animation
            processingAnimation
            
            // Status text
            statusSection
            
            // Progress indicator
            progressSection
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var processingAnimation: some View {
        ZStack {
            // Outer ring with gradient
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )
                .frame(width: 140, height: 140)
            
            // Animated progress ring
            Circle()
                .trim(from: 0, to: viewModel.processingProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: viewModel.processingProgress)
            
            // Center content with AI effect
            VStack(spacing: 8) {
                ZStack {
                    // AI brain icon
                    Image(systemName: "brain")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 4) * 0.1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isProcessing)
                    
                    // Neural network effect
                    ForEach(0..<8) { index in
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 4, height: 4)
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 25,
                                y: sin(Double(index) * .pi / 4) * 25
                            )
                            .scaleEffect(0.5 + sin(Date().timeIntervalSince1970 * 3 + Double(index)) * 0.5)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: viewModel.isProcessing)
                    }
                }
                
                Text("\(Int(viewModel.processingProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            Text("AI Processing...")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Our advanced AI is analyzing your image and removing the background with precision")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress steps
            HStack(spacing: 0) {
                ProcessingStep(
                    title: "Analyzing",
                    isCompleted: viewModel.processingProgress > 0.3,
                    isActive: viewModel.processingProgress <= 0.3
                )
                
                ProcessingConnector(isActive: viewModel.processingProgress > 0.3)
                
                ProcessingStep(
                    title: "Detecting",
                    isCompleted: viewModel.processingProgress > 0.6,
                    isActive: viewModel.processingProgress > 0.3 && viewModel.processingProgress <= 0.6
                )
                
                ProcessingConnector(isActive: viewModel.processingProgress > 0.6)
                
                ProcessingStep(
                    title: "Removing",
                    isCompleted: viewModel.processingProgress >= 1.0,
                    isActive: viewModel.processingProgress > 0.6
                )
            }
        }
    }
}

struct ProcessingStep: View {
    let title: String
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(stepColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(stepColor)
                } else if isActive {
                    Circle()
                        .fill(stepColor)
                        .frame(width: 12, height: 12)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 4) * 0.3)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isActive)
                } else {
                    Circle()
                        .fill(stepColor.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(stepColor)
        }
    }
    
    private var stepColor: Color {
        if isCompleted {
            return .purple
        } else if isActive {
            return .blue
        } else {
            return .gray
        }
    }
}

struct ProcessingConnector: View {
    let isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(isActive ? Color.purple : Color.gray.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

#Preview {
    RemoveBackgroundProcessingView(viewModel: {
        let vm = RemoveBackgroundViewModel()
        vm.isProcessing = true
        vm.processingProgress = 0.7
        return vm
    }())
}