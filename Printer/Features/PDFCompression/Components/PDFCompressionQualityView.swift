import SwiftUI

struct PDFCompressionQualityView: View {
    @ObservedObject var viewModel: PDFCompressionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // File info section
            if let documentURL = viewModel.selectedDocument {
                fileInfoSection(documentURL)
            }
            
            // Quality selection section
            qualitySelectionSection
            
            Spacer()
            
            // Compress button
            compressButton
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func fileInfoSection(_ documentURL: URL) -> some View {
        VStack(spacing: 16) {
            Text("YOUR FILE")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
                    Text(documentURL.lastPathComponent)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(formatFileSize(viewModel.originalFileSize))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var qualitySelectionSection: some View {
        VStack(spacing: 16) {
            Text("CHOOSE COMPRESS QUALITY")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 30)
            
            VStack(spacing: 12) {
                ForEach(CompressionLevel.allCases, id: \.rawValue) { level in
                    CompressionLevelCard(
                        level: level,
                        isSelected: viewModel.selectedCompressionLevel == level
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedCompressionLevel = level
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var compressButton: some View {
        Button {
            viewModel.compressPDF()
        } label: {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16))
                Text("Compress")
                    .font(.headline)
            }
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
        .disabled(viewModel.selectedDocument == nil)
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct CompressionLevelCard: View {
    let level: CompressionLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(level.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Compression preview
                CompressionPreview(level: level)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.blue.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompressionPreview: View {
    let level: CompressionLevel
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(compressionColor(for: index))
                        .frame(width: 3, height: compressionHeight(for: index))
                }
            }
            
            Text("\(compressionPercentage)%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    private func compressionColor(for index: Int) -> Color {
        switch level {
        case .extreme:
            return index < 1 ? .green : .green.opacity(0.3)
        case .recommended:
            return index < 2 ? .blue : .blue.opacity(0.3)
        case .less:
            return index < 4 ? .orange : .orange.opacity(0.3)
        }
    }
    
    private func compressionHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        switch level {
        case .extreme:
            return index < 1 ? baseHeight : baseHeight * 0.5
        case .recommended:
            return index < 2 ? baseHeight : baseHeight * 0.5
        case .less:
            return index < 4 ? baseHeight : baseHeight * 0.5
        }
    }
    
    private var compressionPercentage: Int {
        Int((1.0 - level.compressionRatio) * 100)
    }
}

#Preview {
    PDFCompressionQualityView(viewModel: {
        let vm = PDFCompressionViewModel()
        vm.selectedDocument = URL(string: "file:///example.pdf")
        return vm
    }())
}