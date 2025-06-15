//
//  WebView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let webViewManager: WebViewManager
    
    func makeUIView(context: Context) -> WKWebView {
        return webViewManager.webView ?? WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Updates handled by WebViewManager
    }
}