//
//  WebViewManager.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import WebKit

class WebViewManager: NSObject, ObservableObject {
    @Published var urlString = "https://www.google.com"
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var pageTitle = ""
    
    var webView: WKWebView?
    
    override init() {
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self
        webView?.allowsBackForwardNavigationGestures = true
        
        // Set default user agent to mobile
        setMobileUserAgent()
    }
    
    func loadDefaultURL() {
        loadURL()
    }
    
    func loadURL() {
        guard let webView = webView else { return }
        
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
            let request = URLRequest(url: url)
            webView.load(request)
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
    
    func toggleDesktopMode(_ isDesktop: Bool) {
        guard let webView = webView else { return }
        
        if isDesktop {
            setDesktopUserAgent()
        } else {
            setMobileUserAgent()
        }
        
        // Reload current page with new user agent
        webView.reload()
    }
    
    private func setMobileUserAgent() {
        let mobileUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
        webView?.customUserAgent = mobileUserAgent
    }
    
    private func setDesktopUserAgent() {
        let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
        webView?.customUserAgent = desktopUserAgent
    }
    
    func printCurrentPage() {
        guard let webView = webView else { return }
        
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = pageTitle.isEmpty ? "Página Web" : pageTitle
        
        printController.printInfo = printInfo
        printController.printFormatter = webView.viewPrintFormatter()
        
        printController.present(animated: true)
    }
    
    func printFullWebsite() {
        // Implementation for full website printing
        printCurrentPage() // For now, same as current page
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
        isLoading = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        
        webView.evaluateJavaScript("document.title") { result, error in
            if let title = result as? String {
                DispatchQueue.main.async {
                    self.pageTitle = title
                }
            }
        }
        
        // Update URL string to reflect current URL
        if let currentURL = webView.url?.absoluteString {
            DispatchQueue.main.async {
                self.urlString = currentURL
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
    }
}
