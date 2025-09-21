import SwiftUI

struct PDFEditorFileSelectionView: View {
    @ObservedObject var viewModel: PDFEditorViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.red)
            }
            .padding(.bottom, 20)
            
            // Title and description
            VStack(spacing: 12) {
                Text(String(localized: "Delete PDF Pages"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(String(localized: "Remove single or multiple pages\nIdentify redundant pages quickly"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Choose file button
            Button {
                viewModel.isShowingFilePicker = true
            } label: {
                Text(String(localized: "Choose file"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    PDFEditorFileSelectionView(viewModel: PDFEditorViewModel())
}