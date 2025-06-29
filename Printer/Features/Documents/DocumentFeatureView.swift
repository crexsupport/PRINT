import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentFeatureView: View {
    @StateObject private var viewModel = DocumentFeatureViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Group {
                if let selectedFile = viewModel.selectedFile {
                    DocumentDisplayView(document: selectedFile, viewModel: viewModel)
                } else {
                    SelectDocumentView(viewModel: viewModel)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if viewModel.selectedFile == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.isShowingFileImporter = true
                }
            }
        }
    }
}

class DocumentFeatureViewModel: ObservableObject {
    @Published var isShowingFileImporter = false
    @Published var selectedFile: BatchFileItem? = nil
    @Published var pdfReloadTrigger = UUID()

    func selectFile(from result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let newItem = BatchFileItem(url: url)
            if newItem.pageCount >= 0 {
                self.selectedFile = newItem
                self.pdfReloadTrigger = UUID()
            } else {
                print("Could not load selected file as a valid PDF: \(url.lastPathComponent)")
                self.selectedFile = nil
                // TODO: Show an error to the user
            }
        case .failure(let error):
            print("Failed to pick file: \(error.localizedDescription)")
            self.selectedFile = nil
            // TODO: Show an error to the user
        }
    }

    func clearSelection() {
        if let file = selectedFile, file.url.isFileURL {
            file.url.stopAccessingSecurityScopedResource()
        }
        self.selectedFile = nil
    }
}

struct SelectDocumentView: View {
    @ObservedObject var viewModel: DocumentFeatureViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70, weight: .light))
                .foregroundColor(colorScheme == .dark ? .blue.opacity(0.8) : .blue)
                .padding(.bottom, 15)
            
            Text("No document selected")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text("Select a document to view, print, or share.")
                .font(.body)
                .fontWeight(.regular)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 50)
            
            Button {
                viewModel.isShowingFileImporter = true
            } label: {
                Label("Select Document", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            
            Spacer()
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
            }
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFileImporter,
            allowedContentTypes: [UTType.pdf, UTType.rtf, UTType.text, UTType.jpeg, UTType.png, UTType.heic],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let firstUrl = urls.first {
                    viewModel.selectFile(from: .success(firstUrl))
                } else {
                    viewModel.selectFile(from: .failure(NSError(domain: "FileImporter", code: 0, userInfo: [NSLocalizedDescriptionKey: "No file selected."])))
                }
            case .failure(let error):
                viewModel.selectFile(from: .failure(error))
                if error.localizedDescription.contains("cancelled") || error.localizedDescription.contains("canceled") {
                    // FIX: Delay dismissal to prevent crash when cancelling file importer.
                    // This is a race condition where the view is dismissed before the
                    // document picker controller has fully cleaned up its delegate proxy.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentDisplayView: View {
    let document: BatchFileItem
    @ObservedObject var viewModel: DocumentFeatureViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            PDFKitView(url: document.url, configuration: .documentViewer)
                .id(viewModel.pdfReloadTrigger)
                .edgesIgnoringSafeArea(.bottom)
                .onAppear {
                    if document.url.isFileURL {
                        let accessGranted = document.url.startAccessingSecurityScopedResource()
                        if !accessGranted {
                            print("DocumentDisplayView: Failed to gain access to \(document.fileName) on appear.")
                            viewModel.pdfReloadTrigger = UUID()
                        } else {
                            print("DocumentDisplayView: Gained access to \(document.fileName) on appear.")
                            viewModel.pdfReloadTrigger = UUID()
                        }
                    }
                }
                .onDisappear {
                    if document.url.isFileURL {
                        document.url.stopAccessingSecurityScopedResource()
                        print("DocumentDisplayView: Stopped accessing \(document.fileName) on disappear.")
                    }
                }
            
            Button {
                print("Printing single document: \(document.fileName)")
            } label: {
                Text("Print Document")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
            }
            .foregroundColor(.white)
            .background(Color.blue)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 3)
            .padding(.bottom, 20)
        }
        .navigationTitle(document.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                 Button {
                     viewModel.clearSelection()
                 } label: {
                     Image(systemName: "chevron.backward")
                 }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ShareLink(item: document.url,
                          subject: Text(document.fileName),
                          message: Text("Check out this document: \(document.fileName)"),
                          preview: SharePreview(document.fileName, image: Image(systemName: "doc.fill"))) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Previews
#Preview("Initial State") {
    DocumentFeatureView()
}
