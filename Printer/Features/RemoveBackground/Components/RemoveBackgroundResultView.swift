import SwiftUI

struct RemoveBackgroundResultView: View {
    @ObservedObject var viewModel: RemoveBackgroundViewModel
    @State private var showingComparison = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Success header
                    successHeader
                    
                    // Image display section
                    imageDisplaySection
                        .frame(height: geometry.size.height * 0.5)
                    
                    // Controls section
                    controlsSection
                    
                    // Action buttons
                    actionButtonsSection
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var successHeader: some View {
        VStack(spacing: 16) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                    .scaleEffect(1.0)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            // Animation handled by the checkmark itself
                        }
                    }
            }
            
            VStack(spacing: 8) {
                Text("Background Removed!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your image is ready with a transparent background")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private var imageDisplaySection: some View {
        ZStack {
            // Checkered background to show transparency
            CheckeredBackground()
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            if showingComparison {
                // Before/After comparison
                comparisonView
            } else {
                // Final result
                if let finalImage = viewModel.getFinalImage() {
                    Image(uiImage: finalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
    }
    
    private var comparisonView: some View {
        HStack(spacing: 10) {
            if let originalImage = viewModel.originalImage {
                VStack(spacing: 8) {
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let processedImage = viewModel.processedImage {
                VStack(spacing: 8) {
                    ZStack {
                        CheckeredBackground()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("After")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            // Comparison toggle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingComparison.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showingComparison ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                    Text(showingComparison ? "Hide Comparison" : "Show Comparison")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Shadow toggle
            Toggle(isOn: $viewModel.addShadow) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.purple)
                    Text("Add Shadow")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .purple))
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Print button
            Button {
                if let finalImage = viewModel.getFinalImage() {
                    printImage(finalImage)
                }
            } label: {
                HStack {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 16))
                    Text("Print Image")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Process another image button
            Button {
                viewModel.resetToSelection()
            } label: {
                Text("Remove Another Background")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private func printImage(_ image: UIImage) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = "Background Removed Image"
        
        printController.printInfo = printInfo
        printController.printingItem = image
        
        printController.present(animated: true)
    }
}

struct CheckeredBackground: View {
    var body: some View {
        Canvas { context, size in
            let squareSize: CGFloat = 20
            let rows = Int(size.height / squareSize) + 1
            let cols = Int(size.width / squareSize) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    let color = isEven ? Color.white : Color.gray.opacity(0.2)
                    
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}

#Preview {
    RemoveBackgroundResultView(viewModel: {
        let vm = RemoveBackgroundViewModel()
        vm.originalImage = UIImage(systemName: "person.fill")
        vm.processedImage = UIImage(systemName: "person.fill")
        return vm
    }())
}