import SwiftUI
import UniformTypeIdentifiers
import PDFKit

// MARK: - Data Models
enum CompressionLevel: String, CaseIterable {
    case extreme = "extreme"
    case recommended = "recommended"
    case less = "less"
    
    var title: String {
        switch self {
        case .extreme:
            return "Extreme compression"
        case .recommended:
            return "Recommended compression"
        case .less:
            return "Less compression"
        }
    }
    
    var subtitle: String {
        switch self {
        case .extreme:
            return "Web / mobile view"
        case .recommended:
            return "Web / mobile view and printing"
        case .less:
            return "Printing quality"
        }
    }
    
    var compressionRatio: Float {
        switch self {
        case .extreme:
            return 0.1 // 90% reduction
        case .recommended:
            return 0.3 // 70% reduction
        case .less:
            return 0.6 // 40% reduction
        }
    }
    
    var jpegQuality: CGFloat {
        switch self {
        case .extreme:
            return 0.3 // Increased from 0.1
        case .recommended:
            return 0.6 // Increased from 0.4
        case .less:
            return 0.8 // Increased from 0.7
        }
    }
    
    var imageScale: CGFloat {
        switch self {
        case .extreme:
            return 0.7 // Increased from 0.4 - less aggressive
        case .recommended:
            return 0.85 // Increased from 0.6
        case .less:
            return 0.95 // Increased from 0.8
        }
    }
}

struct CompressedFileInfo {
    let originalSize: Int64
    let compressedSize: Int64
    let fileName: String
    let compressionLevel: CompressionLevel
    let fileURL: URL
    
    var compressionPercentage: Int {
        let reduction = Double(originalSize - compressedSize) / Double(originalSize)
        return Int(reduction * 100)
    }
    
    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: originalSize, countStyle: .file)
    }
    
    var formattedCompressedSize: String {
        ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file)
    }
}

// MARK: - ViewModel
class PDFCompressionViewModel: ObservableObject {
    @Published var selectedDocument: URL?
    @Published var currentStep: PDFCompressionStep = .introduction
    @Published var selectedCompressionLevel: CompressionLevel = .recommended
    @Published var isProcessing = false
    @Published var compressedFileInfo: CompressedFileInfo?
    @Published var errorMessage: String?
    @Published var showingFilePicker = false
    @Published var processingProgress: Double = 0.0
    
    @Published var originalFileSize: Int64 = 0
    
    func selectDocumentFromFiles() {
        showingFilePicker = true
    }
    
    func selectDocumentFromRecents() {
        // For demo purposes, we'll use the file picker
        // In a real app, this would show recent files
        showingFilePicker = true
    }
    
    func selectDocument(from result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            loadDocument(from: url)
        case .failure(let error):
            errorMessage = "Failed to select document: \(error.localizedDescription)"
        }
    }
    
    private func loadDocument(from url: URL) {
        var accessGranted = false
        if url.isFileURL {
            accessGranted = url.startAccessingSecurityScopedResource()
        } else {
            accessGranted = true
        }
        
        guard accessGranted else {
            errorMessage = "Cannot access the selected file"
            return
        }
        
        // Get file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            originalFileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            if url.isFileURL { url.stopAccessingSecurityScopedResource() }
            errorMessage = "Failed to read file information"
            return
        }
        
        guard PDFDocument(url: url) != nil else {
            if url.isFileURL { url.stopAccessingSecurityScopedResource() }
            errorMessage = "Invalid PDF document"
            return
        }
        
        self.selectedDocument = url
        self.currentStep = .qualitySelection
        
        if url.isFileURL { url.stopAccessingSecurityScopedResource() }
    }
    
    func compressPDF() {
        guard let documentURL = selectedDocument else { return }
        
        isProcessing = true
        currentStep = .processing
        processingProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.performCompression(documentURL: documentURL)
        }
    }
    
    private func performCompression(documentURL: URL) {
        var accessGranted = false
        if documentURL.isFileURL {
            accessGranted = documentURL.startAccessingSecurityScopedResource()
        } else {
            accessGranted = true
        }
        
        guard accessGranted else {
            DispatchQueue.main.async {
                self.errorMessage = "Cannot access the selected file"
                self.isProcessing = false
                self.currentStep = .qualitySelection
            }
            return
        }
        
        guard let document = PDFDocument(url: documentURL) else {
            if documentURL.isFileURL { documentURL.stopAccessingSecurityScopedResource() }
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load PDF document"
                self.isProcessing = false
                self.currentStep = .qualitySelection
            }
            return
        }
        
        // Update progress
        DispatchQueue.main.async {
            self.processingProgress = 0.2
        }
        
        // New compression approach using PDF data optimization
        let compressedDocument = PDFDocument()
        let totalPages = document.pageCount
        
        for i in 0..<totalPages {
            if let page = document.page(at: i) {
                // Create compressed page using image rendering with smaller dimensions
                let compressedPage = self.createCompressedPage(from: page)
                compressedDocument.insert(compressedPage, at: i)
                
                // Update progress
                let pageProgress = Double(i + 1) / Double(totalPages) * 0.6
                DispatchQueue.main.async {
                    self.processingProgress = 0.2 + pageProgress
                }
            }
        }
        
        DispatchQueue.main.async {
            self.processingProgress = 0.8
        }
        
        // Save with compression options
        let outputFileName = self.generateOutputFileName(originalName: documentURL.deletingPathExtension().lastPathComponent)
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputURL = tempDirectory.appendingPathComponent(outputFileName)
        
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        // Get PDF data and compress it
        guard let pdfData = compressedDocument.dataRepresentation() else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to generate PDF data"
                self.isProcessing = false
                self.currentStep = .qualitySelection
            }
            return
        }
        
        // Apply additional compression by reducing quality
        let finalCompressedData = self.compressPDFData(pdfData)
        
        do {
            try finalCompressedData.write(to: outputURL)
            
            // Get compressed file size
            let compressedSize = self.getFileSize(url: outputURL)
            
            let fileInfo = CompressedFileInfo(
                originalSize: self.originalFileSize,
                compressedSize: compressedSize,
                fileName: outputFileName,
                compressionLevel: self.selectedCompressionLevel,
                fileURL: outputURL
            )
            
            DispatchQueue.main.async {
                self.processingProgress = 1.0
                self.compressedFileInfo = fileInfo
                self.isProcessing = false
                self.currentStep = .success
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save compressed PDF: \(error.localizedDescription)"
                self.isProcessing = false
                self.currentStep = .qualitySelection
            }
        }
        
        if documentURL.isFileURL { documentURL.stopAccessingSecurityScopedResource() }
    }
    
    private func createCompressedPage(from page: PDFPage) -> PDFPage {
        let originalBounds = page.bounds(for: .mediaBox)
        
        // Calculate compressed dimensions based on compression level
        let compressionFactor = selectedCompressionLevel.imageScale
        let targetSize = CGSize(
            width: originalBounds.width * compressionFactor,
            height: originalBounds.height * compressionFactor
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.preferredRange = .standard
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        let compressedImage = renderer.image { context in
            // Fill with white background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            let cgContext = context.cgContext
            
            // Save the current state
            cgContext.saveGState()
            
            // Scale to fit the target size
            let scaleX = targetSize.width / originalBounds.width
            let scaleY = targetSize.height / originalBounds.height
            cgContext.scaleBy(x: scaleX, y: scaleY)
            
            // Flip coordinate system for PDF (PDFs have origin at bottom-left)
            cgContext.translateBy(x: 0, y: originalBounds.height)
            cgContext.scaleBy(x: 1, y: -1)
            
            cgContext.interpolationQuality = .high
            cgContext.setAllowsAntialiasing(true)
            cgContext.setShouldAntialias(true)
            
            page.draw(with: .mediaBox, to: cgContext)
            
            cgContext.restoreGState()
        }
        
        var imageData: Data?
        
        // For documents that might be text-heavy, try PNG first
        if selectedCompressionLevel == .less {
            imageData = compressedImage.pngData()
        }
        
        // If PNG is too large or we want more compression, use JPEG
        if imageData == nil || selectedCompressionLevel != .less {
            imageData = compressedImage.jpegData(compressionQuality: selectedCompressionLevel.jpegQuality)
        }
        
        guard let finalImageData = imageData,
              let finalImage = UIImage(data: finalImageData) else {
            return page // Return original if compression fails
        }
        
        // Create new PDF page from compressed image
        return PDFPage(image: finalImage) ?? page
    }
    
    private func compressPDFData(_ data: Data) -> Data {
        // Only apply additional compression for extreme level
        if selectedCompressionLevel == .extreme {
            // Use lighter compression to avoid corruption
            return data.deflated() ?? data
        }
        return data
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func generateOutputFileName(originalName: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "Compress_\(originalName)_\(formatter.string(from: Date())).pdf"
    }
    
    func resetToIntroduction() {
        selectedDocument = nil
        currentStep = .introduction
        selectedCompressionLevel = .recommended
        isProcessing = false
        compressedFileInfo = nil
        errorMessage = nil
        processingProgress = 0.0
        originalFileSize = 0
    }
    
    func returnToPreviousStep() {
        switch currentStep {
        case .qualitySelection:
            resetToIntroduction()
        case .processing:
            currentStep = .qualitySelection
        case .success:
            currentStep = .qualitySelection
        case .introduction:
            break
        }
    }
}

// MARK: - Step Enum
enum PDFCompressionStep {
    case introduction
    case qualitySelection
    case processing
    case success
}

import Compression

extension Data {
    func compressed() -> Data? {
        return self.withUnsafeBytes { bytes in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
            defer { buffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                buffer, count,
                bytes.bindMemory(to: UInt8.self).baseAddress!, count,
                nil, COMPRESSION_LZFSE
            )
            
            guard compressedSize > 0 else { return nil }
            return Data(bytes: buffer, count: compressedSize)
        }
    }
    
    func deflated() -> Data? {
        return self.withUnsafeBytes { bytes in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
            defer { buffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                buffer, count,
                bytes.bindMemory(to: UInt8.self).baseAddress!, count,
                nil, COMPRESSION_LZMA
            )
            
            guard compressedSize > 0 else { return nil }
            return Data(bytes: buffer, count: compressedSize)
        }
    }
}

// MARK: - Main PDFCompressionView
struct PDFCompressionView: View {
    @StateObject private var viewModel = PDFCompressionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.currentStep {
                case .introduction:
                    PDFCompressionIntroView(viewModel: viewModel)
                case .qualitySelection:
                    PDFCompressionQualityView(viewModel: viewModel)
                case .processing:
                    PDFCompressionProcessingView(viewModel: viewModel)
                case .success:
                    PDFCompressionSuccessView(viewModel: viewModel)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if viewModel.currentStep == .introduction {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    } else if viewModel.currentStep != .processing {
                        Button {
                            viewModel.returnToPreviousStep()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .success, let fileInfo = viewModel.compressedFileInfo {
                        ShareLink(item: fileInfo.fileURL,
                                  subject: Text("Compressed PDF"),
                                  message: Text("Check out this compressed PDF"),
                                  preview: SharePreview("Compressed PDF", image: Image(systemName: "doc.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingFilePicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false,
            onCompletion: viewModel.selectDocument
        )
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .introduction:
            return "Compress PDF"
        case .qualitySelection:
            return "Compress PDF"
        case .processing:
            return "Processing..."
        case .success:
            return "Success"
        }
    }
}

#Preview {
    PDFCompressionView()
}
