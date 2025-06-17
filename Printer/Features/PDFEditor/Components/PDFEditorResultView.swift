import SwiftUI

struct PDFEditorResultView: View {
    @ObservedObject var viewModel: PDFEditorViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Success section
            successSection
            
            // PDF Preview section
            if let url = viewModel.processedDocumentURL {
                PDFKitView(url: url, configuration: .documentViewer)
                    .frame(maxHeight: .infinity)
                    .clipped()
            }
            
            // Bottom buttons
            bottomButtons
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var successSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("PDF Edited Successfully!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Deleted \(viewModel.selectedPagesCount) page\(viewModel.selectedPagesCount == 1 ? "" : "s")")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 30)
        .background(Color(.systemBackground))
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Print button
            Button {
                if let url = viewModel.processedDocumentURL {
                    printDocument(url: url)
                }
            } label: {
                HStack {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 16))
                    Text("Print Document")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Edit another PDF button
            Button {
                viewModel.resetToFileSelection()
            } label: {
                Text("Edit Another PDF")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private func printDocument(url: URL) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Edited PDF"
        
        printController.printInfo = printInfo
        printController.printingItem = url
        
        printController.present(animated: true)
    }
}

#Preview {
    PDFEditorResultView(viewModel: PDFEditorViewModel())
}