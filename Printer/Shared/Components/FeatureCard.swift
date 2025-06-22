//
//  FeatureCard.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FeatureCard: View {
    let feature: PrinterFeature
    @EnvironmentObject var scannerManager: ScannerManager
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    // RE-ADD: @State para controlar la presentación modal
    @State private var showingDocumentScannerModal = false
    @State private var showingWebPagesModal = false
    @State private var showingDocumentFileImporter = false
    @State private var selectedDocumentURL: URL? = nil
    @State private var showingPhotoPrintModal = false
    @State private var showingTextNotesModal = false
    @State private var showingBatchPrintModal = false
    @State private var showingPDFEditorModal = false
    @State private var showingImageToPDFModal = false
    @State private var showingCompressPDFModal = false
    
    // AÑADIDO: Para mostrar la vista de revisión después del escaneo
    @State private var showingDocumentReview = false
    @State private var scannedImages: [UIImage] = []
    
    var body: some View {
        Button(action: handleFeatureTap) {
            featureContent
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingDocumentScannerModal, onDismiss: {
            if !scannedImages.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingDocumentReview = true
                }
            }
        }) {
            DocumentScannerView(scannedImages: $scannedImages)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showingDocumentReview) {
            EnhancedDocumentCollectionView(
                images: $scannedImages,
                onSave: {
                    scannedImages.removeAll()
                    showingDocumentReview = false
                },
                onAddMore: {
                    showingDocumentReview = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingDocumentScannerModal = true
                    }
                }
            )
            .environmentObject(subscriptionManager)
            .environmentObject(paywallManager)
        }
        .fullScreenCover(isPresented: $showingWebPagesModal) {
            WebPagesView()
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
        }
        .fullScreenCover(isPresented: $showingPhotoPrintModal) {
            PhotoPrintView(showBackButton: true)
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
        }
        .fullScreenCover(isPresented: $showingTextNotesModal) {
            TextNotesView()
        }
        .fullScreenCover(isPresented: $showingBatchPrintModal) {
            BatchPrintView()
        }
        .fullScreenCover(isPresented: $showingPDFEditorModal) {
            PDFEditorView()
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
        }
        .fullScreenCover(isPresented: $showingImageToPDFModal) {
            ImageToPDFView()
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
        }
        .fileImporter(
            isPresented: $showingDocumentFileImporter,
            allowedContentTypes: [UTType.pdf, UTType.rtf, UTType.text, UTType.jpeg, UTType.png, UTType.heic],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let firstUrl = urls.first {
                    selectedDocumentURL = firstUrl
                    print("Selected document: \(firstUrl.lastPathComponent)")
                }
            case .failure(let error):
                print("Failed to pick document: \(error.localizedDescription)")
            }
        }
        .fullScreenCover(item: $selectedDocumentURL) { url in
            DocumentViewerModal(documentURL: url) {
                selectedDocumentURL = nil
            }
        }
    }
    
    private func handleFeatureTap() {
        switch feature.title {
        case "Scanner":
            scannedImages.removeAll()
            showingDocumentScannerModal = true
        case "Web Pages":
            showingWebPagesModal = true
        case "Documents": // Assuming the title is "Documents"
            showingDocumentFileImporter = true
        case "Photos":
            showingPhotoPrintModal = true
        case "Text Notes":
            showingTextNotesModal = true
        /*
        case "Remove Background":
            showingRemoveBackgroundModal = true
        */
        case "Batch Print", "Batch Print...":
            showingBatchPrintModal = true
        case "PDF Editor":
            showingPDFEditorModal = true
        case "Image to PDF":
            showingImageToPDFModal = true
        /*
        case "Compress PDF":
            showingCompressPDFModal = true
        */
        default:
            print("\(feature.title) tapped, no action defined yet.")
        }
    }
    
    private var featureContent: some View {
        VStack(alignment: .leading, spacing: 3) { // Overall spacing for content elements
            HStack { // Icon Container
                Spacer() // Pushes icon to the right
                Image(systemName: feature.icon)
                    .font(.system(size: 20)) // Icon size
                    .foregroundColor(.white)
                    .padding(5) // Padding inside the icon's background
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .padding(.trailing, 4)

            Spacer(minLength: 2) // Spacer between icon and text

            VStack(alignment: .leading, spacing: 2) { // Text Container
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1) // Title on one line

                Text(feature.description)
                    .font(.caption) 
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1) // Description on one line
            }
            .padding(.horizontal, 8) 
            .padding(.bottom, 6)
        }
        .padding(6) // Overall padding for the entire content block
        .frame(height: 120) 
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(feature.color.gradient)
        )
    }
}

struct DocumentViewerModal: View {
    let documentURL: URL
    let onDismiss: () -> Void
    @State private var hasAccessToFile = false
    @State private var showingPrintAlert = false
    @State private var printAlertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Group {
                    if hasAccessToFile {
                        PDFKitView(url: documentURL, configuration: .documentViewer)
                            .edgesIgnoringSafeArea(.bottom)
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("Loading Document...")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                    }
                }
                .onAppear {
                    if documentURL.isFileURL {
                        hasAccessToFile = documentURL.startAccessingSecurityScopedResource()
                        if !hasAccessToFile {
                            print("Failed to access file: \(documentURL.lastPathComponent)")
                        }
                    } else {
                        hasAccessToFile = true
                    }
                }
                .onDisappear {
                    if documentURL.isFileURL && hasAccessToFile {
                        documentURL.stopAccessingSecurityScopedResource()
                        hasAccessToFile = false
                    }
                }
                
                Button {
                    printDocument()
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
            .navigationTitle(documentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ShareLink(item: documentURL,
                              subject: Text(documentURL.lastPathComponent),
                              message: Text("Check out this document: \(documentURL.lastPathComponent)"),
                              preview: SharePreview(documentURL.lastPathComponent, image: Image(systemName: "doc.fill"))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .alert("Print Status", isPresented: $showingPrintAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(printAlertMessage)
        }
    }
    
    private func printDocument() {
        print("Attempting to print document: \(documentURL.lastPathComponent)")
        
        // Check if printing is available
        guard UIPrintInteractionController.isPrintingAvailable else {
            printAlertMessage = "Printing is not available on this device."
            showingPrintAlert = true
            return
        }
        
        let printController = UIPrintInteractionController.shared
        
        // Configure print info
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = documentURL.lastPathComponent
        printInfo.duplex = .none
        
        printController.printInfo = printInfo
        printController.printingItem = documentURL
        
        // Present the print interface
        printController.present(animated: true) { (controller, completed, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Print error: \(error.localizedDescription)")
                    self.printAlertMessage = "Print failed: \(error.localizedDescription)"
                    self.showingPrintAlert = true
                } else if completed {
                    print("Print job completed successfully")
                    self.printAlertMessage = "Document sent to printer successfully!"
                    self.showingPrintAlert = true
                } else {
                    print("Print job was cancelled")
                    // Don't show alert for cancellation
                }
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    FeatureCard(feature: PrinterFeature.mainFeatures.first(where: { $0.title == "Scanner" }) ?? PrinterFeature.mainFeatures[0])
        .environmentObject(ScannerManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}
