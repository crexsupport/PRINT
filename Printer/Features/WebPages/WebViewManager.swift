//
//  WebViewManager.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import WebKit

class WebViewManager: NSObject, ObservableObject {
    @Published var url: URL = URL(string: "https://www.google.com")!
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var urlString = "https://www.google.com"
    @Published var pageTitle = ""
    @Published var isDesktopMode = false

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
        guard let webView = webView else { return }

        let pdfConfiguration = WKPDFConfiguration()

        webView.createPDF(configuration: pdfConfiguration) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self.savePDFToDocuments(data: data)
                }
            case .failure(let error):
                print("Generación de PDF falló: \(error)")
            }
        }
    }

    private func savePDFToDocuments(data: Data) {
        // Save PDF to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent("pagina_web_\(Date().timeIntervalSince1970).pdf")

        do {
            try data.write(to: pdfURL)
            print("PDF guardado en: \(pdfURL)")
            // Show success message or add to printables
        } catch {
            print("Error al guardar PDF: \(error)")
        }
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
