import SwiftUI

struct PDFCompressionSuccessView: View {
    @ObservedObject var viewModel: PDFCompressionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Success header
            successHeader
            
            // File details
            if let fileInfo = viewModel.compressedFileInfo {
                fileDetailsSection(fileInfo)
            }
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var successHeader: some View {
        VStack(spacing: 24) {
            // Success icon with animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: viewModel.compressedFileInfo != nil)
                
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: viewModel.compressedFileInfo != nil)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.compressedFileInfo != nil)
            }
            
            VStack(spacing: 8) {
                Text("Your compressed PDF File has")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("been saved successfully!")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 50)
        .padding(.horizontal, 20)
    }
    
    private func fileDetailsSection(_ fileInfo: CompressedFileInfo) -> some View {
        VStack(spacing: 16) {
            Text("NEW FILE")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // File card
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // PDF icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fileInfo.fileName)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(fileInfo.formattedCompressedSize)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Compression stats
                compressionStats(fileInfo)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
    
    private func compressionStats(_ fileInfo: CompressedFileInfo) -> some View {
        VStack(spacing: 12) {
            // Size comparison
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(fileInfo.formattedOriginalSize)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Compressed Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(fileInfo.formattedCompressedSize)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            // Reduction percentage
            VStack(spacing: 8) {
                HStack {
                    Text("Size Reduction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(fileInfo.compressionPercentage)% smaller")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                // Visual progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.8), Color.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (Double(fileInfo.compressionPercentage) / 100.0), height: 4)
                            .cornerRadius(2)
                            .animation(.easeInOut(duration: 1.0).delay(0.5), value: fileInfo.compressionPercentage)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.top, 8)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Print button
            Button {
                if let fileInfo = viewModel.compressedFileInfo {
                    printDocument(url: fileInfo.fileURL)
                }
            } label: {
                HStack {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 16))
                    Text("Print")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Go to Files button
            Button {
                openFilesApp()
            } label: {
                Text("Go to Files")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    private func printDocument(url: URL) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Compressed PDF"
        
        printController.printInfo = printInfo
        printController.printingItem = url
        
        printController.present(animated: true)
    }
    
    private func openFilesApp() {
        // Open Files app (this would typically open to the location of the saved file)
        if let url = URL(string: "shareddocuments://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    PDFCompressionSuccessView(viewModel: {
        let vm = PDFCompressionViewModel()
        vm.compressedFileInfo = CompressedFileInfo(
            originalSize: 1024000,
            compressedSize: 204800,
            fileName: "Compress jun 16, 2025 15:32:23.pdf",
            compressionLevel: .recommended,
            fileURL: URL(fileURLWithPath: "/tmp/example.pdf")
        )
        return vm
    }())
}