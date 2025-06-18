import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ImageToPDFResultView: View {
    @ObservedObject var viewModel: ImageToPDFViewModel
    @State private var showingDocumentPicker = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var documentToExport: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Enhanced PDF Preview section
                enhancedPDFPreview
                
                // Bottom buttons
                bottomButtons
            }
        }
        .background(Color(.systemBackground))
        .fileExporter(
            isPresented: $showingDocumentPicker,
            document: documentToExport.map { PDFDocumentFile(url: $0) },
            contentType: .pdf,
            defaultFilename: generateDefaultFilename()
        ) { result in
            switch result {
            case .success(let url):
                saveAlertMessage = "PDF saved successfully to \(url.lastPathComponent)"
                showingSaveAlert = true
                print("PDF saved to: \(url)")
            case .failure(let error):
                saveAlertMessage = "Failed to save PDF: \(error.localizedDescription)"
                showingSaveAlert = true
                print("Save error: \(error)")
            }
        }
        .alert("Save Status", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private var enhancedPDFPreview: some View {
        VStack(spacing: 16) {
            // Preview header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PREVIEW")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("PDF Document")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Orientation badge
                HStack(spacing: 6) {
                    Image(systemName: viewModel.selectedOrientation.icon)
                        .font(.system(size: 12))
                    Text(viewModel.selectedOrientation.title)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20) // Safe area padding
            
            // Smart PDF preview with 3D effect
            if let url = viewModel.generatedPDFURL {
                SmartPDFPreviewView(
                    url: url,
                    orientation: viewModel.selectedOrientation,
                    pageCount: viewModel.selectedImages.count
                )
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Print button with enhanced design
            Button {
                if let url = viewModel.generatedPDFURL {
                    printDocument(url: url)
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "printer.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Print PDF")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Convert more images button
            Button {
                viewModel.resetToImageSelection()
            } label: {
                Text("Convert More Images")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Button {
                if let url = viewModel.generatedPDFURL {
                    savePDFToFiles(url: url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Save to Files")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
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
        printInfo.jobName = "Images PDF"
        
        printController.printInfo = printInfo
        printController.printingItem = url
        
        printController.present(animated: true)
    }
    
    private func savePDFToFiles(url: URL) {
        // Create a persistent copy of the PDF in Documents directory
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = generateDefaultFilename()
            let persistentURL = documentsPath.appendingPathComponent(fileName)
            
            // Remove existing file if it exists
            try? FileManager.default.removeItem(at: persistentURL)
            
            // Copy the temporary file to a persistent location
            try FileManager.default.copyItem(at: url, to: persistentURL)
            
            // Set the document to export and show picker
            documentToExport = persistentURL
            showingDocumentPicker = true
            
            print("Created persistent copy at: \(persistentURL)")
            
        } catch {
            saveAlertMessage = "Failed to prepare PDF for saving: \(error.localizedDescription)"
            showingSaveAlert = true
            print("Failed to create persistent copy: \(error)")
        }
    }
    
    private func generateDefaultFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "Images_to_PDF_\(formatter.string(from: Date())).pdf"
    }
}

struct PDFDocumentFile: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        // This shouldn't be called for export
        throw CocoaError(.fileReadCorruptFile)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
}

struct SmartPDFPreviewView: View {
    let url: URL
    let orientation: PDFOrientation
    let pageCount: Int
    
    @State private var currentPage = 0
    @State private var showFullScreen = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 3D-style preview container
            ZStack {
                // Background cards for depth effect - only show if multiple pages
                if pageCount > 1 {
                    ForEach(1..<min(3, pageCount), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            .frame(height: orientation == .portrait ? 320 : 240)
                            .scaleEffect(1.0 - CGFloat(index) * 0.02)
                            .offset(
                                x: CGFloat(index) * -6,
                                y: CGFloat(index) * -6
                            )
                            .opacity(0.8 - CGFloat(index) * 0.2)
                    }
                }
                
                // Main preview container
                previewContainer
            }
            .padding(.horizontal, 20)
            
            // Page navigation if multiple pages
            if pageCount > 1 {
                pageNavigationControls
            }
            
            // PDF stats
            pdfStatsView
        }
    }
    
    private var previewContainer: some View {
        ZStack {
            // Main card background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // PDF preview content
            VStack(spacing: 0) {
                CustomPDFPreviewView(
                    url: url,
                    currentPage: currentPage,
                    orientation: orientation
                )
                .frame(height: orientation == .portrait ? 320 : 240)
                .cornerRadius(8)
                .padding(12)
                .onTapGesture {
                    showFullScreen = true
                }
            }
            
            // Expand button overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button {
                        showFullScreen = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenPDFView(url: url) {
                showFullScreen = false
            }
        }
    }
    
    private var pageNavigationControls: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(currentPage > 0 ? .blue : .gray)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(.systemGray6)))
            }
            .disabled(currentPage <= 0)
            
            Text("Page \(currentPage + 1) of \(pageCount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentPage < pageCount - 1 {
                        currentPage += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(currentPage < pageCount - 1 ? .blue : .gray)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(.systemGray6)))
            }
            .disabled(currentPage >= pageCount - 1)
        }
        .padding(.horizontal, 20)
    }
    
    private var pdfStatsView: some View {
        HStack(spacing: 0) {
            StatItemView(
                icon: "doc.text",
                title: "Pages",
                value: "\(pageCount)"
            )
            
            Divider()
                .frame(height: 40)
                .opacity(0.3)
            
            StatItemView(
                icon: "rectangle.portrait",
                title: "Format",
                value: "A4"
            )
            
            Divider()
                .frame(height: 40)
                .opacity(0.3)
            
            StatItemView(
                icon: orientation.icon,
                title: "Size",
                value: orientation.title
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Custom PDF Preview Component
struct CustomPDFPreviewView: UIViewRepresentable {
    let url: URL
    let currentPage: Int
    let orientation: PDFOrientation
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        configurePDFView(pdfView)
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Load document if not already loaded
        if pdfView.document == nil {
            loadDocument(into: pdfView)
        }
        
        // Update current page
        if let document = pdfView.document,
           currentPage < document.pageCount,
           let page = document.page(at: currentPage) {
            pdfView.go(to: page)
        }
    }
    
    private func configurePDFView(_ pdfView: PDFView) {
        // Basic configuration
        pdfView.backgroundColor = UIColor.systemGray6
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
        pdfView.pageBreakMargins = UIEdgeInsets.zero
        
        // Disable user interaction for preview
        pdfView.isUserInteractionEnabled = false
        
        // Configure scroll view
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.isScrollEnabled = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        loadDocument(into: pdfView)
    }
    
    private func loadDocument(into pdfView: PDFView) {
        // Load PDF document
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            
            // Configure scaling after document is loaded
            DispatchQueue.main.async {
                self.configureScaling(for: pdfView, with: document)
            }
        }
    }
    
    private func configureScaling(for pdfView: PDFView, with document: PDFDocument) {
        guard let firstPage = document.page(at: 0) else { return }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        let viewBounds = pdfView.bounds
        
        // Calculate scale to fit the entire page in the view
        let margin: CGFloat = 12
        let availableWidth = viewBounds.width - (margin * 2)
        let availableHeight = viewBounds.height - (margin * 2)
        
        let widthScale = availableWidth / pageBounds.width
        let heightScale = availableHeight / pageBounds.height
        let scale = min(widthScale, heightScale) // Fit entire page
        
        // Ensure we don't scale too small
        let finalScale = max(scale, 0.1)
        
        pdfView.scaleFactor = finalScale
        pdfView.minScaleFactor = finalScale
        pdfView.maxScaleFactor = finalScale // Lock scale for preview
        
        // Center the page with proper margins
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset = UIEdgeInsets(
                top: margin,
                left: margin,
                bottom: margin,
                right: margin
            )
            
            // Center content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let contentSize = scrollView.contentSize
                let viewSize = scrollView.bounds.size
                
                let offsetX = max((contentSize.width - viewSize.width) / 2, -margin)
                let offsetY = max((contentSize.height - viewSize.height) / 2, -margin)
                
                scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
            }
        }
        
        // Go to current page
        if currentPage < document.pageCount,
           let page = document.page(at: currentPage) {
            pdfView.go(to: page)
        }
    }
}

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FullScreenPDFView: View {
    let url: URL
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced PDF viewer that shows all pages
                EnhancedPDFKitView(url: url)
                    .background(Color(.systemGray6))
                
                // Floating close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            onDismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Enhanced PDF Viewer for Full Screen
struct EnhancedPDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Load document
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        // Configuration for full screen viewing
        pdfView.backgroundColor = UIColor.systemGray6
        pdfView.displayMode = .singlePageContinuous // Shows all pages in sequence
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
        pdfView.maxScaleFactor = 4.0
        pdfView.minScaleFactor = 0.25
        pdfView.pageBreakMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Enable user interaction
        pdfView.isUserInteractionEnabled = true
        
        // Configure scroll view and scaling
        DispatchQueue.main.async {
            self.configureInitialScale(for: pdfView)
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update if needed
        if pdfView.document?.documentURL != url {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
                DispatchQueue.main.async {
                    self.configureInitialScale(for: pdfView)
                }
            }
        }
    }
    
    private func configureInitialScale(for pdfView: PDFView) {
        guard let document = pdfView.document,
              let firstPage = document.page(at: 0) else { return }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        let viewBounds = pdfView.bounds
        
        // Calculate scale to fit width with margins
        let horizontalMargin: CGFloat = 40
        let availableWidth = viewBounds.width - (horizontalMargin * 2)
        let widthScale = availableWidth / pageBounds.width
        
        // Set scale factors
        let minScale = min(widthScale, 0.5) // Don't go too small
        let maxScale = min(widthScale * 3.0, 4.0) // Reasonable max zoom
        
        pdfView.minScaleFactor = minScale
        pdfView.maxScaleFactor = maxScale
        pdfView.scaleFactor = widthScale // Fit to width, no default zoom
        
        // Configure scroll view
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.showsVerticalScrollIndicator = true
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.contentInsetAdjustmentBehavior = .never
            
            // Set content insets for proper margins
            scrollView.contentInset = UIEdgeInsets(
                top: 20,
                left: horizontalMargin,
                bottom: 100,
                right: horizontalMargin
            )
            scrollView.scrollIndicatorInsets = scrollView.contentInset
            
            // Position at top
            scrollView.setContentOffset(CGPoint(x: -horizontalMargin, y: -20), animated: false)
        }
        
        // Go to first page
        if let firstPage = document.page(at: 0) {
            pdfView.go(to: firstPage)
        }
    }
}

#Preview {
    ImageToPDFResultView(viewModel: ImageToPDFViewModel())
}
