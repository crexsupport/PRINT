import SwiftUI

struct ImageToPDFProcessingView: View {
    @ObservedObject var viewModel: ImageToPDFViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Processing animation
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.blue, lineWidth: 8)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isProcessing)
                
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("Converting to PDF...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Processing \(viewModel.selectedImages.count) image\(viewModel.selectedImages.count == 1 ? "" : "s") into PDF document")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ImageToPDFProcessingView(viewModel: ImageToPDFViewModel())
}
