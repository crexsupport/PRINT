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
        pageBreakMargins: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0),
        displayMode: .singlePageContinuous,
        displayDirection: .vertical,
        autoScales: false,
        minScaleFactor: 0.25,
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
        pdfView.autoScales = config.autoScales
        pdfView.pageBreakMargins = config.pageBreakMargins
        
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        pdfView.maxScaleFactor = config.maxScaleFactor
        
        // Debug: Print document info
        if let document = document {
            print("PDFViewManager - Document loaded with \(document.pageCount) pages")
            print("PDFViewManager - Display mode: \(config.displayMode.rawValue)")
        }
        
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
        
        let horizontalMargin: CGFloat = config.displayMode == .singlePageContinuous ? 16 : 20
        let availableWidth = viewBounds.width - (horizontalMargin * 2)
        let widthScale = availableWidth / pageBounds.width
        
        // Different scaling logic for batch print vs other modes
        let minScale: CGFloat
        if config.displayMode == .singlePageContinuous {
            // For batch print, use a smaller scale to fit more content
            minScale = max(widthScale * 0.8, 0.25) // Reduce scale by 20%
        } else {
            minScale = config.autoScales ? max(widthScale, 0.25) : (config.minScaleFactor ?? max(widthScale, 0.3))
        }
        
        print("PDFViewManager - Document has \(document.pageCount) pages")
        print("PDFViewManager - pageBounds: \(pageBounds), viewBounds: \(viewBounds)")
        print("PDFViewManager - availableWidth: \(availableWidth), widthScale: \(widthScale), minScale: \(minScale)")
        
        pdfView.minScaleFactor = minScale
        pdfView.maxScaleFactor = minScale * config.maxScaleFactor
        
        // Always set the scale factor for batch print to ensure consistent viewing
        pdfView.scaleFactor = minScale
        
        pdfView.go(to: firstPage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Self.positionDocumentAtTop(pdfView: pdfView, horizontalMargin: horizontalMargin, config: config)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Self.positionDocumentAtTop(pdfView: pdfView, horizontalMargin: horizontalMargin, config: config)
        }
    }
    
    private static func positionDocumentAtTop(pdfView: PDFView, horizontalMargin: CGFloat, config: PDFDisplayConfiguration) {
        guard let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else { return }
        
        let topInset: CGFloat = config.displayMode == .singlePageContinuous ? 10 : 10
        let bottomInset: CGFloat = config.displayMode == .singlePageContinuous ? 20 : 100
        
        // For batch print, center the content properly without horizontal offset
        if config.displayMode == .singlePageContinuous {
            scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
            scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 8, bottom: bottomInset, right: 8)
            
            // Center horizontally and position at top
            let topOffset = CGPoint(x: 0, y: -topInset)
            scrollView.setContentOffset(topOffset, animated: false)
        } else {
            scrollView.contentInset = UIEdgeInsets(top: topInset, left: horizontalMargin, bottom: bottomInset, right: horizontalMargin)
            scrollView.scrollIndicatorInsets = scrollView.contentInset
            
            let topOffset = CGPoint(x: -horizontalMargin, y: -topInset)
            scrollView.setContentOffset(topOffset, animated: false)
        }
        
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
