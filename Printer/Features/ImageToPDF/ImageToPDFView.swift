import SwiftUI
import PhotosUI
import PDFKit

// MARK: - Data Models
struct ImageItem: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let originalName: String?
    
    init(image: UIImage, name: String? = nil) {
        self.image = image
        self.originalName = name
    }
}

enum PDFOrientation: CaseIterable {
    case portrait
    case landscape
    
    var title: String {
        switch self {
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        }
    }
    
    var description: String {
        switch self {
        case .portrait: return "Taller than wide"
        case .landscape: return "Wider than tall"
        }
    }
    
    var icon: String {
        switch self {
        case .portrait: return "rectangle.portrait"
        case .landscape: return "rectangle"
        }
    }
    
    var pageSize: CGSize {
        switch self {
        case .portrait: return CGSize(width: 595, height: 842) // A4 Portrait
        case .landscape: return CGSize(width: 842, height: 595) // A4 Landscape
        }
    }
}

// MARK: - ViewModel
class ImageToPDFViewModel: ObservableObject {
    @Published var selectedImages: [ImageItem] = []
    @Published var currentStep: ImageToPDFStep = .imageSelection
    @Published var selectedOrientation: PDFOrientation = .portrait
    @Published var isProcessing = false
    @Published var generatedPDFURL: URL?
    @Published var errorMessage: String?
    @Published var showingImagePicker = false
    
    func addImages(from results: [Result<PhotosPickerItem, Error>]) {
        for result in results {
            switch result {
            case .success(let item):
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                let imageItem = ImageItem(image: image, name: item.itemIdentifier)
                                self.selectedImages.append(imageItem)
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to load image: \(error.localizedDescription)"
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to select image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func moveImages(from source: IndexSet, to destination: Int) {
        selectedImages.move(fromOffsets: source, toOffset: destination)
    }
    
    func proceedToSettings() {
        guard !selectedImages.isEmpty else { return }
        currentStep = .settings
    }
    
    func generatePDF() {
        guard !selectedImages.isEmpty else { return }
        
        isProcessing = true
        currentStep = .processing
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfDocument = PDFDocument()
            let pageSize = self.selectedOrientation.pageSize
            
            for (index, imageItem) in self.selectedImages.enumerated() {
                // Create PDF page from image
                if let pdfPage = self.createPDFPage(from: imageItem.image, size: pageSize) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            // Save PDF
            let outputFileName = self.generatePDFFileName()
            let tempDirectory = FileManager.default.temporaryDirectory
            let outputURL = tempDirectory.appendingPathComponent(outputFileName)
            
            // Remove existing file if any
            try? FileManager.default.removeItem(at: outputURL)
            
            if pdfDocument.write(to: outputURL) {
                DispatchQueue.main.async {
                    self.generatedPDFURL = outputURL
                    self.isProcessing = false
                    self.currentStep = .result
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to generate PDF"
                    self.isProcessing = false
                    self.currentStep = .settings
                }
            }
        }
    }
    
    private func createPDFPage(from image: UIImage, size: CGSize) -> PDFPage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let pdfImage = renderer.image { context in
            // Fill background with white
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Calculate image rect to fit within page while maintaining aspect ratio
            let imageRect = calculateImageRect(for: image.size, in: size)
            image.draw(in: imageRect)
        }
        
        guard let pdfImageData = pdfImage.pngData() else { return nil }
        return PDFPage(image: UIImage(data: pdfImageData) ?? image)
    }
    
    private func calculateImageRect(for imageSize: CGSize, in pageSize: CGSize) -> CGRect {
        let margin: CGFloat = 40
        let availableSize = CGSize(
            width: pageSize.width - 2 * margin,
            height: pageSize.height - 2 * margin
        )
        
        let scale = min(
            availableSize.width / imageSize.width,
            availableSize.height / imageSize.height
        )
        
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        let origin = CGPoint(
            x: (pageSize.width - scaledSize.width) / 2,
            y: (pageSize.height - scaledSize.height) / 2
        )
        
        return CGRect(origin: origin, size: scaledSize)
    }
    
    private func generatePDFFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "Images_to_PDF_\(formatter.string(from: Date())).pdf"
    }
    
    func resetToImageSelection() {
        currentStep = .imageSelection
        // Keep existing images so user can add more or reorder
        // selectedImages = []
        selectedOrientation = .portrait
        isProcessing = false
        generatedPDFURL = nil
        errorMessage = nil
    }
    
    func returnToPreviousStep() {
        switch currentStep {
        case .settings:
            currentStep = .imageSelection
        case .processing:
            currentStep = .settings
        case .result:
            currentStep = .settings
        case .imageSelection:
            break
        }
    }
}

// MARK: - Step Enum
enum ImageToPDFStep {
    case imageSelection
    case settings
    case processing
    case result
}

// MARK: - Main ImageToPDFView
struct ImageToPDFView: View {
    @StateObject private var viewModel = ImageToPDFViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    @State private var showingLocalPaywall = false
    @State private var showingActivitySheet = false
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.currentStep {
                case .imageSelection:
                    ImageToPDFSelectionView(viewModel: viewModel)
                case .settings:
                    ImageToPDFSettingsView(viewModel: viewModel)
                case .processing:
                    ImageToPDFProcessingView(viewModel: viewModel)
                case .result:
                    ImageToPDFResultView(viewModel: viewModel)
                        .environmentObject(subscriptionManager)
                        .environmentObject(paywallManager)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if viewModel.currentStep == .imageSelection {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    } else {
                        Button {
                            viewModel.returnToPreviousStep()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .result, let url = viewModel.generatedPDFURL {
                        Button {
                            handleShareAction(url: url)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingLocalPaywall) {
            PaywallView(onDismiss: {
                showingLocalPaywall = false
            })
            .environmentObject(subscriptionManager)
            .interactiveDismissDisabled(true) // Disable swipe to dismiss
        }
        .sheet(isPresented: $showingActivitySheet) {
            if let url = viewModel.generatedPDFURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
    
    private func handleShareAction(url: URL) {
        if subscriptionManager.isSubscribed {
            // User is subscribed, proceed with sharing
            shareDocument(url: url)
        } else {
            // User is not subscribed, show local paywall
            showingLocalPaywall = true
        }
    }
    
    private func shareDocument(url: URL) {
        showingActivitySheet = true
    }
    
    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .imageSelection:
            return "Image to PDF"
        case .settings:
            return "PDF Settings"
        case .processing:
            return "Converting..."
        case .result:
            return "PDF Generated"
        }
    }
}

#Preview {
    ImageToPDFView()
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}
