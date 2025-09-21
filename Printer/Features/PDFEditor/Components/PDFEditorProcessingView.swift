import SwiftUI

struct PDFEditorProcessingView: View {
    @ObservedObject var viewModel: PDFEditorViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Processing animation
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.red, lineWidth: 8)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isProcessing)
                
                Image(systemName: "scissors")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                Text(String(localized: "Deleting Pages..."))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(String(localized: "Removing \(viewModel.selectedPagesCount) page\(viewModel.selectedPagesCount == 1 ? "" : "s") from your PDF"))
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
    PDFEditorProcessingView(viewModel: PDFEditorViewModel())
}