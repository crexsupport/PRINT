import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import UIKit

// MARK: - Data Model
struct BatchFileItem: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    var fileName: String { url.lastPathComponent }
    var fileType: BatchFileType
    var pageCount: Int

    init(url: URL) {
        self.url = url
        
        // Determine file type
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            self.fileType = .pdf
        case "jpg", "jpeg", "png", "heic", "heif":
            self.fileType = .image
        default:
            self.fileType = .unsupported
        }
        
        var accessGranted = false
        if url.isFileURL {
             accessGranted = url.startAccessingSecurityScopedResource()
        } else {
            accessGranted = true
        }

        if accessGranted {
            switch self.fileType {
            case .pdf:
                if let pdfDocument = PDFDocument(url: url) {
                    self.pageCount = pdfDocument.pageCount
                } else {
                    self.pageCount = 0
                    print("Warning: Could not create PDFDocument for page count: \(url.lastPathComponent)")
                }
            case .image:
                // Images are treated as single-page documents
                self.pageCount = 1
            case .unsupported:
                self.pageCount = 0
                print("Warning: Unsupported file type: \(url.lastPathComponent)")
            }
            
            if url.isFileURL && accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        } else {
            self.pageCount = 0
            print("Warning: Could not access security scoped resource for page count: \(url.lastPathComponent)")
        }
    }
}

enum BatchFileType {
    case pdf
    case image
    case unsupported
    
    var iconName: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .image:
            return "photo.fill"
        case .unsupported:
            return "questionmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .pdf:
            return .red
        case .image:
            return .blue
        case .unsupported:
            return .gray
        }
    }
}

// MARK: - ViewModel
class BatchPrintViewModel: ObservableObject {
    @Published var selectedFiles: [BatchFileItem] = []
    @Published var isShowingFilePicker = false
    @Published var currentStep: BatchPrintStep = .fileSelection
    @Published var mergedDocumentURL: URL?
    @Published var mergedDocumentName: String = ""
    @Published var processingProgress: Double = 0.0
    @Published var processingStatusText: String = "Preparing..."
    @Published var fileForSinglePreview: BatchFileItem? = nil

    let maxFiles = 10

    func addFile(from result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            urls.forEach { url in
                if selectedFiles.count < maxFiles && !selectedFiles.contains(where: { $0.url == url }) {
                    let newItem = BatchFileItem(url: url)
                    if newItem.pageCount > 0 && newItem.fileType != .unsupported {
                        selectedFiles.append(newItem)
                    } else {
                        print("Could not add file \(url.lastPathComponent), possibly not a supported file type or page count is zero.")
                    }
                }
            }
        case .failure(let error):
            print("Failed to pick files: \(error.localizedDescription)")
        }
    }

    func removeFile(item: BatchFileItem) {
        selectedFiles.removeAll { $0.id == item.id }
    }

    func startBatchPrintProcess() {
        guard !selectedFiles.isEmpty else { return }

        currentStep = .processing
        processingProgress = 0.0
        processingStatusText = "Preparing to merge..."

        DispatchQueue.global(qos: .userInitiated).async {
            let mergedPdf = PDFDocument()
            let totalFiles = self.selectedFiles.count
            var processedFiles = 0
            var totalPagesAdded = 0

            print("DEBUG: Starting merge process with \(totalFiles) files")

            for (index, fileItem) in self.selectedFiles.enumerated() {
                DispatchQueue.main.async {
                    self.processingStatusText = "Processing: \(fileItem.fileName) (\(index + 1) of \(totalFiles))"
                    self.processingProgress = (Double(index) / Double(totalFiles)) * 0.8
                }

                var accessGranted = false
                if fileItem.url.isFileURL {
                    accessGranted = fileItem.url.startAccessingSecurityScopedResource()
                } else {
                    accessGranted = true
                }

                guard accessGranted else {
                    print("ERROR: Could not access file \(fileItem.fileName)")
                    continue
                }

                var pagesAddedFromThisFile = 0

                switch fileItem.fileType {
                case .pdf:
                    guard let sourcePdf = PDFDocument(url: fileItem.url) else {
                        print("ERROR: Could not create PDFDocument for \(fileItem.fileName)")
                        if fileItem.url.isFileURL { fileItem.url.stopAccessingSecurityScopedResource() }
                        continue
                    }

                    print("DEBUG: Processing PDF \(fileItem.fileName) with \(sourcePdf.pageCount) pages")
                    
                    for i in 0..<sourcePdf.pageCount {
                        guard let page = sourcePdf.page(at: i) else {
                            print("ERROR: Could not get page \(i) from \(fileItem.fileName)")
                            continue
                        }
                        mergedPdf.insert(page, at: mergedPdf.pageCount)
                        pagesAddedFromThisFile += 1
                        totalPagesAdded += 1
                    }
                    
                case .image:
                    print("DEBUG: Processing image \(fileItem.fileName)")
                    
                    guard let imageData = try? Data(contentsOf: fileItem.url),
                          let image = UIImage(data: imageData) else {
                        print("ERROR: Could not load image from \(fileItem.fileName)")
                        if fileItem.url.isFileURL { fileItem.url.stopAccessingSecurityScopedResource() }
                        continue
                    }
                    
                    if let pdfPage = self.createPDFPageFromImage(image) {
                        mergedPdf.insert(pdfPage, at: mergedPdf.pageCount)
                        pagesAddedFromThisFile += 1
                        totalPagesAdded += 1
                        print("DEBUG: Successfully added image page from \(fileItem.fileName)")
                    } else {
                        print("ERROR: Failed to create PDF page from image \(fileItem.fileName)")
                    }
                    
                case .unsupported:
                    print("ERROR: Unsupported file type for \(fileItem.fileName)")
                }

                if fileItem.url.isFileURL {
                    fileItem.url.stopAccessingSecurityScopedResource()
                }
                
                processedFiles += 1
                print("DEBUG: Processed file \(fileItem.fileName), added \(pagesAddedFromThisFile) pages. Total pages so far: \(totalPagesAdded)")
            }

            print("DEBUG: Merge complete. Processed \(processedFiles) files, total pages: \(totalPagesAdded)")

            DispatchQueue.main.async {
                self.processingStatusText = "Finalizing and saving merged PDF..."
                self.processingProgress = 0.85
            }

            // Ensure we have pages to save
            guard mergedPdf.pageCount > 0 else {
                print("ERROR: No pages were added to the merged PDF")
                DispatchQueue.main.async {
                    self.processingStatusText = "Error: No pages were successfully processed."
                    self.currentStep = .fileSelection
                }
                return
            }

            let outputFileName = self.generateMergedPdfName()
            let tempDirectory = FileManager.default.temporaryDirectory
            let outputUrl = tempDirectory.appendingPathComponent(outputFileName)

            // Remove existing file if it exists
            try? FileManager.default.removeItem(at: outputUrl)

            print("DEBUG: Attempting to save merged PDF with \(mergedPdf.pageCount) pages to \(outputUrl)")

            if mergedPdf.write(to: outputUrl) {
                print("DEBUG: Successfully saved merged PDF")
                DispatchQueue.main.async {
                    self.mergedDocumentURL = outputUrl
                    self.mergedDocumentName = outputFileName
                    self.processingProgress = 1.0
                    self.processingStatusText = "Merge successful! \(totalPagesAdded) pages merged."
                    self.currentStep = .preview
                }
            } else {
                print("ERROR: Failed to save merged PDF to disk")
                DispatchQueue.main.async {
                    self.processingStatusText = "Error: Failed to save merged PDF."
                    self.currentStep = .fileSelection
                }
            }
        }
    }

    // MARK: - Helper method to create PDF page from UIImage (improved)
    private func createPDFPageFromImage(_ image: UIImage) -> PDFPage? {
        // Standard A4 size in points (8.27 x 11.69 inches at 72 DPI)
        let pageSize = CGSize(width: 595.2, height: 841.8)
        
        // Calculate the aspect ratios
        let imageAspectRatio = image.size.width / image.size.height
        let pageAspectRatio = pageSize.width / pageSize.height
        
        // Calculate the size to fit the image within the page while maintaining aspect ratio
        let margin: CGFloat = 40 // 40 points margin on all sides
        let availableSize = CGSize(width: pageSize.width - (margin * 2), height: pageSize.height - (margin * 2))
        
        let drawSize: CGSize
        if imageAspectRatio > pageAspectRatio {
            // Image is wider than page - fit to width
            drawSize = CGSize(
                width: availableSize.width,
                height: availableSize.width / imageAspectRatio
            )
        } else {
            // Image is taller than page or same ratio - fit to height
            drawSize = CGSize(
                width: availableSize.height * imageAspectRatio,
                height: availableSize.height
            )
        }
        
        // Center the image on the page
        let drawOrigin = CGPoint(
            x: (pageSize.width - drawSize.width) / 2,
            y: (pageSize.height - drawSize.height) / 2
        )
        
        // Create PDF data directly
        let pageData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pageData, CGRect(origin: .zero, size: pageSize), nil)
        UIGraphicsBeginPDFPage()
        
        // Get the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            print("ERROR: Could not get graphics context for image conversion")
            return nil
        }
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: pageSize))
        
        // Draw the image
        let drawRect = CGRect(origin: drawOrigin, size: drawSize)
        image.draw(in: drawRect)
        
        UIGraphicsEndPDFContext()
        
        // Create PDFDocument from the data and extract the first page
        guard let pdfDocument = PDFDocument(data: pageData as Data),
              let createdPage = pdfDocument.page(at: 0) else {
            print("ERROR: Failed to create PDFDocument from image data")
            return nil
        }
        
        return createdPage
    }

    // MARK: - Remove old createPDFPage method

    func generateMergedPdfName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "MergedDocument_\(formatter.string(from: Date())).pdf"
    }

    func selectFileForSinglePreview(_ file: BatchFileItem) {
        // For images, we need to create a temporary PDF to preview
        if file.fileType == .image {
            createTemporaryPDFForImage(file)
        } else {
            fileForSinglePreview = file
            currentStep = .singleFilePreview
        }
    }
    
    private func createTemporaryPDFForImage(_ imageFile: BatchFileItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            var accessGranted = false
            if imageFile.url.isFileURL {
                accessGranted = imageFile.url.startAccessingSecurityScopedResource()
            } else {
                accessGranted = true
            }
            
            guard accessGranted else {
                print("Error: Could not access image file for preview")
                return
            }
            
            guard let imageData = try? Data(contentsOf: imageFile.url),
                  let image = UIImage(data: imageData) else {
                print("Error: Could not load image for preview")
                if imageFile.url.isFileURL && accessGranted {
                    imageFile.url.stopAccessingSecurityScopedResource()
                }
                return
            }
            
            let tempPdf = PDFDocument()
            guard let pdfPage = self.createPDFPageFromImage(image) else {
                print("Error: Could not create PDF page from image for preview")
                if imageFile.url.isFileURL && accessGranted {
                    imageFile.url.stopAccessingSecurityScopedResource()
                }
                return
            }
            tempPdf.insert(pdfPage, at: 0)
            
            let tempFileName = "TempPreview_\(imageFile.fileName).pdf"
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempUrl = tempDirectory.appendingPathComponent(tempFileName)
            
            try? FileManager.default.removeItem(at: tempUrl)
            
            if tempPdf.write(to: tempUrl) {
                // Create a new BatchFileItem for the temporary PDF
                var tempFile = imageFile
                tempFile.url = tempUrl
                tempFile.fileType = .pdf
                
                DispatchQueue.main.async {
                    self.fileForSinglePreview = tempFile
                    self.currentStep = .singleFilePreview
                }
            }
            
            if imageFile.url.isFileURL && accessGranted {
                imageFile.url.stopAccessingSecurityScopedResource()
            }
        }
    }

    func returnToPreviousStep() {
        switch currentStep {
        case .singleFilePreview:
            fileForSinglePreview = nil
            currentStep = .fileSelection
        case .preview: // Back from merged document preview
            currentStep = .fileSelection
        case .processing: // Back from processing (e.g. via cancel button)
            currentStep = .fileSelection
            // Reset progress if cancelling processing
            processingProgress = 0.0
            processingStatusText = "Preparing..."
        default:
            currentStep = .fileSelection
        }
    }

    func resetProcess(clearFiles: Bool = true) {
        if clearFiles {
            selectedFiles.removeAll()
        }
        // Always clear these on a full reset or when explicitly going back to file selection start
        mergedDocumentURL = nil
        mergedDocumentName = ""
        fileForSinglePreview = nil
        
        currentStep = .fileSelection
        processingProgress = 0.0
        processingStatusText = "Preparing..."
    }
}

// MARK: - Main Step Enum
enum BatchPrintStep {
    case fileSelection
    case processing
    case preview // For merged document
    case singleFilePreview
}

// MARK: - Main BatchPrintView (Orchestrator)
struct BatchPrintView: View {
    @StateObject private var viewModel = BatchPrintViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.currentStep {
                case .fileSelection:
                    BatchFileSelectionView(viewModel: viewModel)
                case .processing:
                    BatchProcessingView(viewModel: viewModel)
                case .preview:
                    BatchPreviewView(viewModel: viewModel)
                case .singleFilePreview:
                    SingleFilePreviewView(viewModel: viewModel)
                }
            }
            .navigationTitle(navigationTitleForCurrentStep())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if viewModel.currentStep != .fileSelection {
                        Button {
                            viewModel.returnToPreviousStep()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .preview, let url = viewModel.mergedDocumentURL {
                        ShareLink(item: url,
                                  subject: Text(viewModel.mergedDocumentName),
                                  message: Text("Check out this merged document: \(viewModel.mergedDocumentName)"),
                                  preview: SharePreview(viewModel.mergedDocumentName, image: Image(systemName: "doc.text.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else if viewModel.currentStep == .singleFilePreview, let fileItem = viewModel.fileForSinglePreview {
                        ShareLink(item: fileItem.url,
                                  subject: Text(fileItem.fileName),
                                  message: Text("Check out this document: \(fileItem.fileName)"),
                                  preview: SharePreview(fileItem.fileName, image: Image(systemName: fileItem.fileType.iconName))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .toolbar(viewModel.currentStep == .preview || viewModel.currentStep == .singleFilePreview ? .hidden : .automatic, for: .tabBar)
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: [UTType.pdf, UTType.jpeg, UTType.png, UTType.heic, UTType.heif],
            allowsMultipleSelection: true,
            onCompletion: viewModel.addFile
        )
    }

    private func navigationTitleForCurrentStep() -> String {
        switch viewModel.currentStep {
        case .fileSelection:
            return "Batch Print"
        case .processing:
            return "Processing Batch"
        case .preview:
            return viewModel.mergedDocumentName.isEmpty ? "Preview" : viewModel.mergedDocumentName
        case .singleFilePreview:
            return viewModel.fileForSinglePreview?.fileName ?? "Document"
        }
    }
}

// MARK: - Subview: File Selection
struct BatchFileSelectionView: View {
    @ObservedObject var viewModel: BatchPrintViewModel
    @Environment(\.colorScheme) var colorScheme

    private var sharedBaseBackgroundColor: Color { Color(.systemBackground) }
    private var cardBackgroundColor: Color { Color(.systemBackground) }

    var body: some View {
        Group {
            if viewModel.selectedFiles.isEmpty {
                emptyState
            } else {
                populatedState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sharedBaseBackgroundColor.edgesIgnoringSafeArea(.all))
    }

    private var emptyState: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Modern illustration section
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .offset(x: 15, y: -5)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Batch Print Documents")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Merge multiple PDFs and images into one document for easy printing")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            // Features section
            VStack(spacing: 16) {
                FeatureRowView(icon: "doc.text", title: "Merge PDFs", description: "Combine multiple PDF files")
                FeatureRowView(icon: "photo", title: "Include Images", description: "Add JPEG, PNG, HEIC images")
                FeatureRowView(icon: "printer", title: "Print All", description: "Print everything at once")
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Call to action
            VStack(spacing: 12) {
                Button {
                    viewModel.isShowingFilePicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                        Text("Select Files to Merge")
                            .font(.headline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 30)
                
                Text("Supports up to 10 files")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }

    private var populatedState: some View {
        VStack(spacing: 0) {
            // Header with stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Files")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(viewModel.selectedFiles.count) files • \(totalPages) pages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick stats
                HStack(spacing: 16) {
                    StatBadge(icon: "doc.fill", count: pdfCount, label: "PDFs")
                    StatBadge(icon: "photo.fill", count: imageCount, label: "Images")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Files list
            List {
                ForEach(viewModel.selectedFiles) { fileItem in
                    FileRowView(fileItem: fileItem, onRemove: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            viewModel.removeFile(item: fileItem)
                        }
                    }, onTap: {
                        viewModel.selectFileForSinglePreview(fileItem)
                    })
                }
            }
            .listStyle(.plain)
            .padding(.top, 12)
            .animation(.default, value: viewModel.selectedFiles)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                VStack(spacing: 0) {
                    HStack(spacing: 20) {
                        Button {
                            viewModel.isShowingFilePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.subheadline)
                                Text("Add (\(viewModel.selectedFiles.count)/\(viewModel.maxFiles))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(viewModel.selectedFiles.count >= viewModel.maxFiles)

                        Spacer()

                        Button {
                            viewModel.startBatchPrintProcess()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "printer.fill")
                                    .font(.caption)
                                Text("Merge & Print")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                        }
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(viewModel.selectedFiles.isEmpty)
                    }
                    .padding(.horizontal, 40) // Mucho más padding lateral
                    .padding(.bottom, 12)
                }
            }
        }
    }
    
    // Computed properties for stats
    private var totalPages: Int {
        viewModel.selectedFiles.reduce(0) { $0 + $1.pageCount }
    }
    
    private var pdfCount: Int {
        viewModel.selectedFiles.filter { $0.fileType == .pdf }.count
    }
    
    private var imageCount: Int {
        viewModel.selectedFiles.filter { $0.fileType == .image }.count
    }
}

// MARK: - Helper Views
struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.blue)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct FileRowView: View {
    let fileItem: BatchFileItem
    let onRemove: () -> Void
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon with background
            ZStack {
                Circle()
                    .fill(fileItem.fileType.iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: fileItem.fileType.iconName)
                    .foregroundColor(fileItem.fileType.iconColor)
                    .font(.system(size: 18, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fileItem.fileName)
                    .font(.system(.body, design: .default))
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(fileItem.fileType == .image ? "Image" : "PDF")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(fileItem.fileType.iconColor)
                        .clipShape(Capsule())
                    
                    Text("\(fileItem.pageCount) page\(fileItem.pageCount == 1 ? "" : "s")")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color(.systemGray3))
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.05), radius: 2, x: 0, y: 1)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Subview: Processing
struct BatchProcessingView: View {
    @ObservedObject var viewModel: BatchPrintViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Ready to Merge: \(viewModel.selectedFiles.count) file\(viewModel.selectedFiles.count == 1 ? "" : "s")")
                .font(.title2.weight(.semibold))
                .padding(.bottom)

            HStack(spacing: 12) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                Image(systemName: "plus")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                Image(systemName: "arrow.right")
                     .font(.system(size: 18))
                    .foregroundColor(.gray)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }
            .padding(.bottom)

            VStack(alignment: .leading, spacing: 15) {
                ProgressStepView(label: "1. Organizing Files", isChecked: viewModel.processingProgress >= 0.0)
                ProgressStepView(label: "2. Converting & Merging", isChecked: viewModel.processingProgress >= 0.05 && viewModel.processingProgress < 0.85)
                ProgressStepView(label: "3. Finalizing Document", isChecked: viewModel.processingProgress >= 0.85)
            }
            .padding(.horizontal)
            
            ProgressView(value: viewModel.processingProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding()
                .animation(.linear, value: viewModel.processingProgress)

            Text(viewModel.processingStatusText)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(height: 40, alignment: .top)
                .multilineTextAlignment(.center)

            Spacer()
            Button("Cancel") { // This button cancels the processing
                viewModel.returnToPreviousStep()
            }
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Subview: Preview
struct BatchPreviewView: View {
    @ObservedObject var viewModel: BatchPrintViewModel
    @State private var showingPrintError = false
    @State private var printErrorMessage = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            if let url = viewModel.mergedDocumentURL {
                PDFKitView(url: url, configuration: .batchPrint)
                    .edgesIgnoringSafeArea(.bottom)
            } else {
                VStack {
                    Spacer()
                    ContentUnavailableView(title: "Preview Unavailable",
                                           systemImage: "doc.viewfinder.fill",
                                           description: Text("The merged PDF could not be displayed."))
                    Spacer()
                }
            }

            Button {
                printDocument()
            } label: {
                Text("Print Document")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .alert("Print Error", isPresented: $showingPrintError) {
            Button("OK") { }
        } message: {
            Text(printErrorMessage)
        }
    }
    
    private func printDocument() {
        guard let url = viewModel.mergedDocumentURL else {
            printErrorMessage = "No document available to print."
            showingPrintError = true
            return
        }
        
        // Start accessing security scoped resource if needed
        let accessGranted = url.startAccessingSecurityScopedResource()
        
        guard let pdfDocument = PDFDocument(url: url) else {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
            printErrorMessage = "Could not load the document for printing."
            showingPrintError = true
            return
        }
        
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = viewModel.mergedDocumentName
        printInfo.duplex = .none
        
        printController.printInfo = printInfo
        printController.printingItem = url
        
        printController.present(animated: true) { [weak printController] (printController, completed, error) in
            // Stop accessing security scoped resource
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    printErrorMessage = "Print failed: \(error.localizedDescription)"
                    showingPrintError = true
                }
            } else if completed {
                print("Print job completed successfully")
            } else {
                print("Print job was cancelled")
            }
        }
    }
}

// MARK: - Subview: Single File Preview
struct SingleFilePreviewView: View {
    @ObservedObject var viewModel: BatchPrintViewModel
    @State private var pdfReloadTrigger = UUID()
    @State private var showingPrintError = false
    @State private var printErrorMessage = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            if let file = viewModel.fileForSinglePreview {
                PDFKitView(url: file.url, configuration: .batchPrint)
                    .id(pdfReloadTrigger)
                    .edgesIgnoringSafeArea(.bottom)
                    .onAppear {
                        if file.url.isFileURL {
                            let accessGranted = file.url.startAccessingSecurityScopedResource()
                            if !accessGranted {
                                print("SingleFilePreviewView: Failed to gain access to \(file.fileName) on appear.")
                                // Consider showing an error to the user
                            } else {
                                print("SingleFilePreviewView: Gained access to \(file.fileName) on appear.")
                                // Trigger a re-creation of PDFKitView now that access is (hopefully) granted
                                pdfReloadTrigger = UUID()
                            }
                        }
                    }
                    .onDisappear {
                        if file.url.isFileURL {
                            file.url.stopAccessingSecurityScopedResource()
                            print("SingleFilePreviewView: Stopped accessing \(file.fileName) on disappear.")
                        }
                    }
            } else {
                VStack {
                    Spacer()
                    ContentUnavailableView(title: "Document Unavailable",
                                           systemImage: "doc.questionmark.fill",
                                           description: Text("The selected document could not be displayed."))
                    Spacer()
                }
            }

            if let file = viewModel.fileForSinglePreview {
                Button {
                    printSingleFile(file)
                } label: {
                    Text("Print This File")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 3)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        // Navigation bar is handled by the parent BatchPrintView
    }
    
    private func printSingleFile(_ file: BatchFileItem) {
        // Start accessing security scoped resource if needed
        let accessGranted = file.url.startAccessingSecurityScopedResource()
        
        guard let pdfDocument = PDFDocument(url: file.url) else {
            if accessGranted {
                file.url.stopAccessingSecurityScopedResource()
            }
            printErrorMessage = "Could not load the document for printing."
            showingPrintError = true
            return
        }
        
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = file.fileName
        printInfo.duplex = .none
        
        printController.printInfo = printInfo
        printController.printingItem = file.url
        
        printController.present(animated: true) { [weak printController] (printController, completed, error) in
            // Stop accessing security scoped resource
            if accessGranted {
                file.url.stopAccessingSecurityScopedResource()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    printErrorMessage = "Print failed: \(error.localizedDescription)"
                    showingPrintError = true
                }
            } else if completed {
                print("Print job completed successfully for: \(file.fileName)")
            } else {
                print("Print job was cancelled for: \(file.fileName)")
            }
        }
    }
}

// MARK: - Auxiliary Views
struct ProgressStepView: View {
    let label: String
    let isChecked: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isChecked ? .green : .gray.opacity(0.6))
                .animation(.easeInOut(duration: 0.3), value: isChecked)
            Text(label)
                .font(.body)
                .foregroundColor(isChecked ? .primary : .secondary)
        }
    }
}

// MARK: - Preview
struct ContentUnavailableView: View {
    let title: String
    let systemImage: String
    let description: Text

    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.largeTitle)
            Text(title)
                .font(.title)
            description
                .font(.body)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Preview
struct Preview: PreviewProvider {
    static var previews: some View {
        BatchPrintView()
    }
}
