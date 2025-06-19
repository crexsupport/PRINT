import SwiftUI
import UniformTypeIdentifiers
import PDFKit

// MARK: - Data Models
struct PDFPageItem: Identifiable {
    let id = UUID()
    let page: PDFPage
    let pageNumber: Int
    var isSelected: Bool = false
    
    var thumbnail: UIImage? {
        page.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
    }
}

// MARK: - ViewModel
class PDFEditorViewModel: ObservableObject {
    @Published var selectedDocument: URL?
    @Published var pages: [PDFPageItem] = []
    @Published var isShowingFilePicker = false
    @Published var currentStep: PDFEditorStep = .fileSelection
    @Published var isProcessing = false
    @Published var processedDocumentURL: URL?
    @Published var errorMessage: String?
    
    private var originalDocument: PDFDocument?
    
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
        
        guard let document = PDFDocument(url: url) else {
            if url.isFileURL { url.stopAccessingSecurityScopedResource() }
            errorMessage = "Invalid PDF document"
            return
        }
        
        self.originalDocument = document
        self.selectedDocument = url
        
        // Create page items
        var pageItems: [PDFPageItem] = []
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                pageItems.append(PDFPageItem(page: page, pageNumber: i + 1))
            }
        }
        self.pages = pageItems
        self.currentStep = .pageSelection
        
        if url.isFileURL { url.stopAccessingSecurityScopedResource() }
    }
    
    func togglePageSelection(at index: Int) {
        guard index < pages.count else { return }
        pages[index].isSelected.toggle()
    }
    
    func selectAllPages() {
        for i in 0..<pages.count {
            pages[i].isSelected = true
        }
    }
    
    func deselectAllPages() {
        for i in 0..<pages.count {
            pages[i].isSelected = false
        }
    }
    
    var selectedPagesCount: Int {
        pages.filter { $0.isSelected }.count
    }
    
    var canDeletePages: Bool {
        selectedPagesCount > 0 && selectedPagesCount < pages.count
    }
    
    func deleteSelectedPages() {
        guard canDeletePages, let originalDoc = originalDocument else { return }
        
        isProcessing = true
        currentStep = .processing
        
        DispatchQueue.global(qos: .userInitiated).async {
            let newDocument = PDFDocument()
            
            // Add non-selected pages to new document
            for pageItem in self.pages {
                if !pageItem.isSelected {
                    newDocument.insert(pageItem.page, at: newDocument.pageCount)
                }
            }
            
            // Save the new document
            let outputFileName = self.generateOutputFileName()
            let tempDirectory = FileManager.default.temporaryDirectory
            let outputURL = tempDirectory.appendingPathComponent(outputFileName)
            
            // Remove existing file if any
            try? FileManager.default.removeItem(at: outputURL)
            
            if newDocument.write(to: outputURL) {
                DispatchQueue.main.async {
                    self.processedDocumentURL = outputURL
                    self.isProcessing = false
                    self.currentStep = .result
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save the edited PDF"
                    self.isProcessing = false
                    self.currentStep = .pageSelection
                }
            }
        }
    }
    
    private func generateOutputFileName() -> String {
        let originalName = selectedDocument?.deletingPathExtension().lastPathComponent ?? "document"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "\(originalName)_edited_\(formatter.string(from: Date())).pdf"
    }
    
    func resetToFileSelection() {
        selectedDocument = nil
        pages = []
        currentStep = .fileSelection
        isProcessing = false
        processedDocumentURL = nil
        errorMessage = nil
        originalDocument = nil
    }
    
    func returnToPreviousStep() {
        switch currentStep {
        case .pageSelection:
            resetToFileSelection()
        case .processing:
            currentStep = .pageSelection
        case .result:
            currentStep = .pageSelection
        case .fileSelection:
            break
        }
    }
}

// MARK: - Step Enum
enum PDFEditorStep {
    case fileSelection
    case pageSelection
    case processing
    case result
}

// MARK: - Main PDFEditorView
struct PDFEditorView: View {
    @StateObject private var viewModel = PDFEditorViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    @State private var showingLocalPaywall = false
    @State private var showingActivitySheet = false
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.currentStep {
                case .fileSelection:
                    PDFEditorFileSelectionView(viewModel: viewModel)
                case .pageSelection:
                    PDFEditorPageSelectionView(viewModel: viewModel)
                        .environmentObject(subscriptionManager)
                        .environmentObject(paywallManager)
                case .processing:
                    PDFEditorProcessingView(viewModel: viewModel)
                case .result:
                    PDFEditorResultView(viewModel: viewModel)
                        .environmentObject(subscriptionManager)
                        .environmentObject(paywallManager)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if viewModel.currentStep == .fileSelection {
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
                    if viewModel.currentStep == .result, let url = viewModel.processedDocumentURL {
                        Button {
                            handleShareAction(url: url)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
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
        .sheet(isPresented: $showingLocalPaywall) {
            PaywallView(onDismiss: {
                showingLocalPaywall = false
            })
            .environmentObject(subscriptionManager)
            .interactiveDismissDisabled(true) // Disable swipe to dismiss
        }
        .sheet(isPresented: $showingActivitySheet) {
            if let url = viewModel.processedDocumentURL {
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
        case .fileSelection:
            return "Delete PDF Pages"
        case .pageSelection:
            return "Select Pages to Delete"
        case .processing:
            return "Processing..."
        case .result:
            return "PDF Edited"
        }
    }
}

#Preview {
    PDFEditorView()
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}
