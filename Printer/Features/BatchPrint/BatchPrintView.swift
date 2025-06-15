import SwiftUI
import UniformTypeIdentifiers
import PDFKit

// MARK: - Data Model
struct BatchFileItem: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    var fileName: String { url.lastPathComponent }
    var pageCount: Int

    init(url: URL) {
        self.url = url
        var accessGranted = false
        if url.isFileURL {
             accessGranted = url.startAccessingSecurityScopedResource()
        } else {
            accessGranted = true
        }

        if accessGranted {
            if let pdfDocument = PDFDocument(url: url) {
                self.pageCount = pdfDocument.pageCount
            } else {
                self.pageCount = 0
                print("Warning: Could not create PDFDocument for page count: \(url.lastPathComponent)")
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
                    if newItem.pageCount > 0 {
                        selectedFiles.append(newItem)
                    } else {
                        print("Could not add file \(url.lastPathComponent), possibly not a valid PDF or page count is zero.")
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

            for (index, fileItem) in self.selectedFiles.enumerated() {
                DispatchQueue.main.async {
                    self.processingStatusText = "Processing: \(fileItem.fileName) (\(index + 1) of \(totalFiles))"
                    self.processingProgress = (Double(index) / Double(totalFiles)) * 0.8
                }

                var accessGranted = false
                if fileItem.url.isFileURL {
                    accessGranted = fileItem.url.startAccessingSecurityScopedResource()
                } else {
                    accessGranted = true;
                }

                guard accessGranted, let sourcePdf = PDFDocument(url: fileItem.url) else {
                    print("Error: Could not create or access PDFDocument for \(fileItem.fileName)")
                    if fileItem.url.isFileURL && accessGranted { fileItem.url.stopAccessingSecurityScopedResource() }
                    DispatchQueue.main.async {
                        self.processingStatusText = "Error with \(fileItem.fileName). Skipping."
                    }
                    continue
                }

                for i in 0..<sourcePdf.pageCount {
                    guard let page = sourcePdf.page(at: i) else {
                        print("Error: Could not get page \(i) from \(fileItem.fileName)")
                        continue
                    }
                    mergedPdf.insert(page, at: mergedPdf.pageCount)
                }

                if fileItem.url.isFileURL && accessGranted {
                    fileItem.url.stopAccessingSecurityScopedResource()
                }
            }

            DispatchQueue.main.async {
                self.processingStatusText = "Finalizing and saving merged PDF..."
                self.processingProgress = 0.85
            }

            let outputFileName = self.generateMergedPdfName()
            let tempDirectory = FileManager.default.temporaryDirectory
            let outputUrl = tempDirectory.appendingPathComponent(outputFileName)

            try? FileManager.default.removeItem(at: outputUrl)

            if mergedPdf.write(to: outputUrl) {
                DispatchQueue.main.async {
                    self.mergedDocumentURL = outputUrl
                    self.mergedDocumentName = outputFileName
                    self.processingProgress = 1.0
                    self.processingStatusText = "Merge successful!"
                    self.currentStep = .preview
                }
            } else {
                DispatchQueue.main.async {
                    self.processingStatusText = "Error: Failed to save merged PDF."
                    self.currentStep = .fileSelection
                }
            }
        }
    }
    
    func generateMergedPdfName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "MergedPDF_\(formatter.string(from: Date())).pdf"
    }

    func selectFileForSinglePreview(_ file: BatchFileItem) {
        fileForSinglePreview = file
        currentStep = .singleFilePreview
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
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .preview, let url = viewModel.mergedDocumentURL {
                        ShareLink(item: url,
                                  subject: Text(viewModel.mergedDocumentName),
                                  message: Text("Check out this merged PDF: \(viewModel.mergedDocumentName)"),
                                  preview: SharePreview(viewModel.mergedDocumentName, image: Image(systemName: "doc.text.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else if viewModel.currentStep == .singleFilePreview, let fileItem = viewModel.fileForSinglePreview {
                        ShareLink(item: fileItem.url,
                                  subject: Text(fileItem.fileName),
                                  message: Text("Check out this PDF: \(fileItem.fileName)"),
                                  preview: SharePreview(fileItem.fileName, image: Image(systemName: "doc.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .toolbar(viewModel.currentStep == .preview || viewModel.currentStep == .singleFilePreview ? .hidden : .automatic, for: .tabBar)
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: [UTType.pdf],
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
        VStack(spacing: 25) {
            Spacer()
            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 70, weight: .light))
                .foregroundColor(colorScheme == .dark ? .blue.opacity(0.8) : .blue)
                .padding(.bottom, 15)
            
            Text("Add, merge, and print multiple PDF documents.")
                .font(.headline)
                .fontWeight(.regular)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 50)
            
            Button {
                viewModel.isShowingFilePicker = true
            } label: {
                Label("Add Documents", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.blue)
            
            Spacer()
            Spacer()
        }
        .padding()
    }

    private var populatedState: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.selectedFiles) { fileItem in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.red)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileItem.fileName)
                                .font(.system(.body, design: .default))
                                .lineLimit(1)
                            Text("\(fileItem.pageCount) page\(fileItem.pageCount == 1 ? "" : "s")")
                                .font(.system(.caption, design: .default))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button {
                            viewModel.removeFile(item: fileItem)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.callout)
                                .foregroundColor(Color(.systemGray2))
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.8), lineWidth: 1))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.07), radius: 4, x: 0, y: 2)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .center)), removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .center))))
                    .contentShape(Rectangle()) // Make the whole row tappable
                    .onTapGesture {
                        viewModel.selectFileForSinglePreview(fileItem)
                    }
                }
            }
            .listStyle(.plain)
            .padding(.top, 8)
            .animation(.default, value: viewModel.selectedFiles)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: 0) {
                    Button {
                        viewModel.isShowingFilePicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.headline)
                            Text("Add (\(viewModel.selectedFiles.count)/\(viewModel.maxFiles))")
                                .font(.headline)
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
                        Text("Print")
                            .font(.headline)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                    }
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(viewModel.selectedFiles.isEmpty)
                }
                .padding(.bottom, 5)
            }
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
                 Image(systemName: "doc.on.doc")
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
                ProgressStepView(label: "2. Merging Documents", isChecked: viewModel.processingProgress >= 0.05 && viewModel.processingProgress < 0.85)
                ProgressStepView(label: "3. Finalizing Merge", isChecked: viewModel.processingProgress >= 0.85)
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
                print("Initiate printing for: \(viewModel.mergedDocumentName)")
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
    }
}

// MARK: - Subview: Single File Preview
struct SingleFilePreviewView: View {
    @ObservedObject var viewModel: BatchPrintViewModel
    @State private var pdfReloadTrigger = UUID()

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

            if viewModel.fileForSinglePreview != nil {
                Button {
                    // TODO: Implement actual print logic for viewModel.fileForSinglePreview.url
                    print("Printing single file: \(viewModel.fileForSinglePreview?.fileName ?? "N/A")")
                } label: {
                    Text("Print This File")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent) // Solid blue background
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 3)
                .padding(.bottom, 20) // Position above safe area bottom / tab bar
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)) // Consistent background
        // Navigation bar is handled by the parent BatchPrintView
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
