import SwiftUI

struct TextPreviewView: View {
    @ObservedObject var viewModel: TextNotesViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Main content in a ScrollView for the whole screen
            ScrollView {
                LazyVStack(spacing: 20) { // Reduced spacing between pages
                    // Generate pages that match PDF exactly
                    ForEach(0..<viewModel.getPageCount(), id: \.self) { pageIndex in
                        // Each page as it will appear in PDF
                        VStack(spacing: 0) {
                            // Main text content area - EXACT PDF layout
                            VStack(alignment: .leading, spacing: 0) {
                                Text(viewModel.getTextForPage(pageIndex))
                                    .font(.system(size: 11, design: .default)) // PDF font
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2) // PDF-like line spacing
                                    .tracking(0) // No letter spacing
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .padding(.horizontal, 30) // Reduced from 40 to 30
                                    .padding(.top, 40)
                                    .padding(.bottom, 60)
                                
                                Spacer() // Fill remaining space to maintain fixed page size
                            }
                            .padding(.horizontal, 0) // Removed horizontal padding
                            .padding(.top, 0) // Removed top padding
                            .padding(.bottom, 0) // Removed bottom padding
                            
                            // Simple page indicator at bottom
                            if viewModel.getPageCount() > 1 {
                                HStack {
                                    Spacer()
                                    Text("Page \(pageIndex + 1) of \(viewModel.getPageCount())")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray.opacity(0.6))
                                    Spacer()
                                }
                                .padding(.bottom, 15)
                            }
                        }
                        .background(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 1000) // Much taller like real A4
                        .cornerRadius(0) // No rounded corners like real PDF
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5) // PDF-like shadow
                        .padding(.horizontal, 8) // Reduced from 12 to 8
                        .overlay(
                            // PDF-like border
                            Rectangle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .padding(.horizontal, 8) // Reduced from 12 to 8
                        )
                    }
                    
                    // Extra space for floating button
                    Spacer()
                        .frame(height: 120)
                }
                .padding(.top, 20)
            }
            
            // Floating Print button with modern design
            Button {
                viewModel.printText()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Print Document")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .background(Color.blue.opacity(0.9)) // More opaque
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Safe area bottom padding
            .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4) // Reduced shadow opacity too
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        TextPreviewView(viewModel: {
            let vm = TextNotesViewModel()
            vm.inputText = "This is a very long text that should span multiple pages when there is enough content to fill more than one page. Let me add more text to demonstrate the pagination feature working correctly. This should create at least two pages of content. Here's even more content to ensure we get multiple pages for testing the preview functionality. The text should wrap properly and show pagination as expected."
            vm.currentStep = .preview
            return vm
        }())
        .navigationTitle("Print Text Notes")
    }
}
