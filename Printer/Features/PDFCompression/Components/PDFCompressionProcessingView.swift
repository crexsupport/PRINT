import SwiftUI

struct PDFCompressionProcessingView: View {
    @ObservedObject var viewModel: PDFCompressionViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Processing animation
            processingAnimation
            
            // Status text
            statusSection
            
            // Progress bar
            progressSection
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(Color(.systemBackground))
    }
    
    private var processingAnimation: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 8)
                .frame(width: 120, height: 120)
            
            // Animated progress ring
            Circle()
                .trim(from: 0, to: viewModel.processingProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: viewModel.processingProgress)
            
            // Center content
            VStack(spacing: 8) {
                // Compression icon with animation
                ZStack {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3) * 0.1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isProcessing)
                    
                    // Compression waves
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            .frame(width: 30 + CGFloat(index * 10), height: 30 + CGFloat(index * 10))
                            .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2 + Double(index) * 0.5) * 0.2)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isProcessing)
                    }
                }
                
                Text("\(Int(viewModel.processingProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            Text("Compressing PDF...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Reducing file size while maintaining quality")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.processingProgress, height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.processingProgress)
                }
            }
            .frame(height: 6)
            
            // Progress steps
            HStack {
                ProgressStep(
                    title: "Loading",
                    isCompleted: viewModel.processingProgress > 0.2,
                    isActive: viewModel.processingProgress <= 0.2
                )
                
                Spacer()
                
                ProgressStep(
                    title: "Compressing",
                    isCompleted: viewModel.processingProgress > 0.8,
                    isActive: viewModel.processingProgress > 0.2 && viewModel.processingProgress <= 0.8
                )
                
                Spacer()
                
                ProgressStep(
                    title: "Saving",
                    isCompleted: viewModel.processingProgress >= 1.0,
                    isActive: viewModel.processingProgress > 0.8 && viewModel.processingProgress < 1.0
                )
            }
        }
    }
}

struct ProgressStep: View {
    let title: String
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(stepColor.opacity(0.2))
                    .frame(width: 20, height: 20)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(stepColor)
                } else if isActive {
                    Circle()
                        .fill(stepColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 4) * 0.2)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isActive)
                } else {
                    Circle()
                        .fill(stepColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(stepColor)
        }
    }
    
    private var stepColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .green
        } else {
            return .gray
        }
    }
}

#Preview {
    PDFCompressionProcessingView(viewModel: {
        let vm = PDFCompressionViewModel()
        vm.isProcessing = true
        vm.processingProgress = 0.6
        return vm
    }())
}