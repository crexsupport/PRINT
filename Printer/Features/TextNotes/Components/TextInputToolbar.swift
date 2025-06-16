import SwiftUI

struct TextInputToolbar: View {
    @ObservedObject var viewModel: TextNotesViewModel
    let onDismissKeyboard: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Done/OK button
                Button("OK") {
                    onDismissKeyboard()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.blue)
                
                Spacer()
                
                // Character count
                Text("\(viewModel.characterCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Print button (only show if text exists)
                if viewModel.hasText {
                    Button("Print") {
                        onDismissKeyboard()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.showPreview()
                        }
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        TextInputToolbar(
            viewModel: TextNotesViewModel(),
            onDismissKeyboard: {}
        )
    }
}
