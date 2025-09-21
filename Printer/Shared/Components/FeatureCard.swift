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
    @State private var showingPrintablesModal = false
    @State private var showingCompressPDFModal = false
    @State private var showingLabelsModal = false
    
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
        .fullScreenCover(isPresented: $showingPrintablesModal) {
            PrintablesView()
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
        }
        .fullScreenCover(isPresented: $showingLabelsModal) {
            LabelCreationView()
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
        case String(localized: "Scanner"):
            scannedImages.removeAll()
            showingDocumentScannerModal = true
        case String(localized: "Web Pages"):
            showingWebPagesModal = true
        case String(localized: "Documents"): // Assuming the title is "Documents"
            showingDocumentFileImporter = true
        case String(localized: "Photos"):
            showingPhotoPrintModal = true
        case String(localized: "Text Notes"):
            showingTextNotesModal = true
        case String(localized: "Labels"):
            showingLabelsModal = true
        /*
        case "Remove Background":
            showingRemoveBackgroundModal = true
        */
        case String(localized: "Batch Print"), String(localized: "Batch Print..."):
            showingBatchPrintModal = true
        case String(localized: "PDF Editor"):
            showingPDFEditorModal = true
        case String(localized: "Image to PDF"):
            showingImageToPDFModal = true
        case String(localized: "Printables"):
            showingPrintablesModal = true
        /*
        case "Compress PDF":
            showingCompressPDFModal = true
        */
        default:
            print("\(feature.title) tapped, no action defined yet.")
        }
    }
    
    private var featureContent: some View {
        cardContent
            .background(cardBackground)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(feature.color)
                    .frame(width: 34, height: 34)
                    .background(feature.color.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                
                Spacer()
            }
            .padding(.top, 14)
            .padding(.leading, 14)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.80))
                    .lineLimit(1)
                
                Text(feature.description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var cardBackground: some View {
        ZStack {
            // Base relief background (como WelcomeBannerView)
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white, location: 0.0),
                            .init(color: Color.white, location: 0.97),
                            .init(color: Color.gray.opacity(0.05), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .stroke(Color.gray.opacity(0.30), lineWidth: 0.5)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
            
            // Overlay de color de la feature (como WelcomeBannerView)
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            feature.color.opacity(0.10), // Más oscuro arriba-izquierda
                            feature.color.opacity(0.05)  // Un poco más oscuro abajo-derecha
                        ],
                        startPoint: UnitPoint(x: 0.0, y: 0.0),
                        endPoint: UnitPoint(x: 0.7, y: 0.7)
                    )
                )
        }
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
                            
                            Text(String(localized: "Loading Document..."))
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
                    Text(String(localized: "Print Document"))
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
        .alert(String(localized: "Print Status"), isPresented: $showingPrintAlert) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(printAlertMessage)
        }
    }
    
    private func printDocument() {
        print("Attempting to print document: \(documentURL.lastPathComponent)")
        
        // Check if printing is available
        guard UIPrintInteractionController.isPrintingAvailable else {
            printAlertMessage = String(localized: "Printing is not available on this device.")
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
                    self.printAlertMessage = String(localized: "Print failed: \(error.localizedDescription)")
                    self.showingPrintAlert = true
                } else if completed {
                    print("Print job completed successfully")
                    self.printAlertMessage = String(localized: "Document sent to printer successfully!")
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

// Extensión para obtener los componentes RGB de un Color
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        // Para esta implementación simplificada, usaremos valores aproximados
        // En una implementación más completa, se podría usar UIColor para extraer los componentes reales
        return (red: 0.5, green: 0.5, blue: 0.5, opacity: 1.0) // Valores por defecto
    }
}

#Preview {
    FeatureCard(feature: PrinterFeature.mainFeatures.first(where: { $0.title == "Scanner" }) ?? PrinterFeature.mainFeatures[0])
        .environmentObject(ScannerManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
        .padding()
        .background(Color.white)
}