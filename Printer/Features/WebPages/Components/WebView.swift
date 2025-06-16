//
//  WebView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @ObservedObject var webViewManager: WebViewManager
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Configurar el WebView
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        
        // Establecer la relación con el manager
        webViewManager.setWebView(webView)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Asegurar que el manager tiene la referencia correcta
        if webViewManager.webView !== uiView {
            webViewManager.setWebView(uiView)
        }
    }
}
