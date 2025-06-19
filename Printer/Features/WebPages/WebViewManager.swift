//
//  WebViewManager.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct WebPagePDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    let data: Data
    let title: String
    
    init(data: Data, title: String) {
        self.data = data
        self.title = title
    }
    
    init(configuration: ReadConfiguration) throws {
        // This shouldn't be called for export
        throw CocoaError(.fileReadCorruptFile)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

class WebViewManager: NSObject, ObservableObject {
    @Published var url: URL = URL(string: "https://www.google.com")!
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var urlString = "https://www.google.com"
    @Published var pageTitle = ""
    @Published var isDesktopMode = false
    
    @Published var pdfGenerationResult: PDFResult?
    
    enum PDFResult {
        case success(Data)
        case failure(Error)
    }

    weak var webView: WKWebView?

    override init() {
        super.init()
    }

    func setWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        
        // Configurar User Agent inicial
        updateUserAgent()
        
        // Cargar la URL inicial automáticamente
        DispatchQueue.main.async {
            self.loadURL(self.urlString)
        }
    }

    func loadURL() {
        loadURL(urlString)
    }

    func loadURL(_ urlString: String) {
        var urlToLoad = urlString

        // Add https:// if no protocol specified
        if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
            // Check if it looks like a URL
            if urlToLoad.contains(".") && !urlToLoad.contains(" ") {
                urlToLoad = "https://" + urlToLoad
            } else {
                // Treat as search query
                urlToLoad = "https://www.google.com/search?q=" + urlToLoad.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
        }

        if let url = URL(string: urlToLoad) {
            DispatchQueue.main.async {
                self.url = url
                self.urlString = urlToLoad
                self.webView?.load(URLRequest(url: url))
            }
        }
    }
    
    func toggleDesktopMode() {
        isDesktopMode.toggle()
        updateUserAgent()
        reload()
    }
    
    private func updateUserAgent() {
        guard let webView = webView else { return }
        
        if isDesktopMode {
            // Desktop User Agent (Safari en macOS)
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"
        } else {
            // Mobile User Agent (Safari en iOS) - o nil para usar el por defecto
            webView.customUserAgent = nil
        }
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func printWebPage() {
        guard let webView = webView else { return }

        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = !pageTitle.isEmpty ? pageTitle : "Web Page"

        printController.printInfo = printInfo
        printController.printFormatter = webView.viewPrintFormatter()

        printController.present(animated: true) { (controller, completed, error) in
            if let error = error {
                print("Print error: \(error.localizedDescription)")
            } else if completed {
                print("Print completed successfully")
            }
        }
    }

    func printCurrentPage() {
        printWebPage()
    }

    func printFullWebsite() {
        // Implementation for full website printing
        printWebPage() // For now, same as current page
    }

    func saveAsPDF() {
        guard let webView = webView else { 
            DispatchQueue.main.async {
                self.pdfGenerationResult = .failure(NSError(domain: "WebViewManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "WebView not available"]))
            }
            return 
        }

        let pdfConfiguration = WKPDFConfiguration()
        
        // Configure PDF settings for better quality
        pdfConfiguration.rect = CGRect.null // Use the entire content

        webView.createPDF(configuration: pdfConfiguration) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.pdfGenerationResult = .success(data)
                    print("PDF generated successfully, size: \(data.count) bytes")
                case .failure(let error):
                    self.pdfGenerationResult = .failure(error)
                    print("PDF generation failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func clearPDFResult() {
        pdfGenerationResult = nil
    }

}

// MARK: - WKNavigationDelegate
extension WebViewManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }

        webView.evaluateJavaScript("document.title") { result, error in
            if let title = result as? String {
                DispatchQueue.main.async {
                    self.pageTitle = title
                }
            }
        }

        // Update URL string to reflect current URL
        if let currentURL = webView.url {
            DispatchQueue.main.async {
                self.url = currentURL
                self.urlString = currentURL.absoluteString
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}
