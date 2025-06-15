import SwiftUI
import PDFKit

// MARK: - PDF Display Configuration
struct PDFDisplayConfiguration {
    let backgroundColor: UIColor
    let pageBreakMargins: UIEdgeInsets
    let displayMode: PDFDisplayMode
    let displayDirection: PDFDisplayDirection
    let autoScales: Bool
    let minScaleFactor: CGFloat?
    let maxScaleFactor: CGFloat
    let showCompleteDocument: Bool
    
    static let `default` = PDFDisplayConfiguration(
        backgroundColor: UIColor.systemGray5,
        pageBreakMargins: UIEdgeInsets.zero,
        displayMode: .singlePage,
        displayDirection: .vertical,
        autoScales: false,
        minScaleFactor: nil,
        maxScaleFactor: 5.0,
        showCompleteDocument: true
    )
    
    static let documentViewer = PDFDisplayConfiguration(
        backgroundColor: UIColor.systemGray5,
        pageBreakMargins: UIEdgeInsets.zero,
        displayMode: .singlePage,
        displayDirection: .vertical,
        autoScales: false,
        minScaleFactor: nil,
        maxScaleFactor: 5.0,
        showCompleteDocument: true
    )
    
    static let batchPrint = PDFDisplayConfiguration(
        backgroundColor: UIColor.systemGray5,
        pageBreakMargins: UIEdgeInsets.zero,
        displayMode: .singlePage,
        displayDirection: .vertical,
        autoScales: false,
        minScaleFactor: nil,
        maxScaleFactor: 5.0,
        showCompleteDocument: true
    )
}

// MARK: - PDF View Manager
class PDFViewManager {
    
    static func configurePDFView(_ pdfView: PDFView, with config: PDFDisplayConfiguration, document: PDFDocument?) {
        // Basic configuration
        pdfView.backgroundColor = config.backgroundColor
        pdfView.displayMode = config.displayMode
        pdfView.displayDirection = config.displayDirection
        pdfView.autoScales = false
        pdfView.pageBreakMargins = UIEdgeInsets.zero
        
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        pdfView.maxScaleFactor = config.maxScaleFactor
        
        DispatchQueue.main.async {
            Self.configureZoomLimits(for: pdfView, with: config)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            Self.configureZoomLimits(for: pdfView, with: config)
        }
    }
    
    private static func configureZoomLimits(for pdfView: PDFView, with config: PDFDisplayConfiguration) {
        guard let document = pdfView.document, document.pageCount > 0 else { return }
        guard let firstPage = document.page(at: 0) else { return }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        let viewBounds = pdfView.bounds
        
        let horizontalMargin: CGFloat = 20
        let availableWidth = viewBounds.width - (horizontalMargin * 2)
        let widthScale = availableWidth / pageBounds.width
        
        let minScale = max(widthScale, 0.3)
        
        print("PDFViewManager - pageBounds: \(pageBounds), viewBounds: \(viewBounds)")
        print("PDFViewManager - availableWidth: \(availableWidth), widthScale: \(widthScale), minScale: \(minScale)")
        
        pdfView.minScaleFactor = minScale
        pdfView.maxScaleFactor = minScale * config.maxScaleFactor
        pdfView.scaleFactor = minScale
        
        pdfView.go(to: firstPage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Self.positionDocumentAtTop(pdfView: pdfView, horizontalMargin: horizontalMargin)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Self.positionDocumentAtTop(pdfView: pdfView, horizontalMargin: horizontalMargin)
        }
    }
    
    private static func positionDocumentAtTop(pdfView: PDFView, horizontalMargin: CGFloat) {
        guard let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else { return }
        
        scrollView.contentInset = UIEdgeInsets(top: 10, left: horizontalMargin, bottom: 100, right: horizontalMargin)
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        
        let topOffset = CGPoint(x: -horizontalMargin, y: -10)
        scrollView.setContentOffset(topOffset, animated: false)
        
        print("PDFViewManager - Set contentInset: \(scrollView.contentInset)")
        print("PDFViewManager - Set contentOffset: \(scrollView.contentOffset)")
    }
}

// MARK: - Reusable PDFKitView
struct PDFKitView: UIViewRepresentable {
    let url: URL
    let configuration: PDFDisplayConfiguration
    
    init(url: URL, configuration: PDFDisplayConfiguration = .default) {
        self.url = url
        self.configuration = configuration
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            PDFViewManager.configurePDFView(pdfView, with: configuration, document: document)
        } else {
            print("PDFKitView: Failed to load PDF document from URL: \(url.lastPathComponent)")
            PDFViewManager.configurePDFView(pdfView, with: configuration, document: nil)
        }
        
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            if let document = PDFDocument(url: url) {
                uiView.document = document
                PDFViewManager.configurePDFView(uiView, with: configuration, document: document)
            } else {
                print("PDFKitView: Failed to update PDF document from URL: \(url.lastPathComponent)")
            }
        }
    }
}

// MARK: - Specialized PDF Views
struct DocumentViewerPDFView: View {
    let url: URL
    
    var body: some View {
        PDFKitView(url: url, configuration: .documentViewer)
    }
}

struct BatchPrintPDFView: View {
    let url: URL
    
    var body: some View {
        PDFKitView(url: url, configuration: .batchPrint)
    }
}
