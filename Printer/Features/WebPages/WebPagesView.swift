//
//  WebPagesView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import WebKit

struct WebPagesView: View {
    // MARK: - State / Env
    @StateObject private var webViewManager = WebViewManager()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isURLFieldFocused: Bool

    @State private var showingPrintOptions = false

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager

    @State private var showingLocalPaywall = false
    
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var showingFilePicker = false
    @State private var pdfDataToSave: Data?

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            header
            urlBar
            
            // WebView content area
            WebView(webViewManager: webViewManager)
                .clipped()
            
            bottomNav
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            webViewManager.loadURL()
        }
        .actionSheet(isPresented: $showingPrintOptions) {
            ActionSheet(
                title: Text(String(localized: "Print Options")),
                message: Text(String(localized: "Choose how to print this web page")),
                buttons: [
                    .default(Text(String(localized: "Print Current Page"))) { handlePrintCurrentPage() },
                    .default(Text(String(localized: "Print Full Website"))) { handlePrintFullWebsite() },
                    .default(Text(String(localized: "Save as PDF")))        { handleSaveAsPDF() },
                    .cancel(Text(String(localized: "Cancel")))
                ]
            )
        }
        .sheet(isPresented: $showingLocalPaywall) {
            PaywallView(onDismiss: {
                showingLocalPaywall = false
            })
            .environmentObject(subscriptionManager)
            .interactiveDismissDisabled(true) // Disable swipe to dismiss
        }
        .fileExporter(
            isPresented: $showingFilePicker,
            document: pdfDataToSave.map { WebPagePDFDocument(data: $0, title: webViewManager.pageTitle) },
            contentType: .pdf,
            defaultFilename: generatePDFFilename()
        ) { result in
            switch result {
            case .success(let url):
                showingSaveSuccess = true
                print("PDF saved successfully to: \(url)")
            case .failure(let error):
                saveErrorMessage = "Failed to save PDF: \(error.localizedDescription)"
                showingSaveError = true
                print("Save error: \(error)")
            }
            // Clear the data after use
            pdfDataToSave = nil
        }
        .alert(String(localized: "PDF Saved Successfully"), isPresented: $showingSaveSuccess) {
            Button(String(localized: "OK")) { }
        } message: {
            Text(String(localized: "Your webpage has been saved as a PDF to your chosen location."))
        }
        .alert(String(localized: "Save Failed"), isPresented: $showingSaveError) {
            Button(String(localized: "OK")) { }
        } message: {
            Text(saveErrorMessage)
        }
        .onReceive(webViewManager.$pdfGenerationResult) { result in
            handlePDFGenerationResult(result)
        }
    }
    
    private func handlePrintCurrentPage() {
        if subscriptionManager.isSubscribed {
            webViewManager.printCurrentPage()
        } else {
            showingLocalPaywall = true
        }
    }
    
    private func handlePrintFullWebsite() {
        if subscriptionManager.isSubscribed {
            webViewManager.printFullWebsite()
        } else {
            showingLocalPaywall = true
        }
    }
    
    private func handleSaveAsPDF() {
        if subscriptionManager.isSubscribed {
            webViewManager.saveAsPDF()
        } else {
            showingLocalPaywall = true
        }
    }
    
    private func handlePDFGenerationResult(_ result: WebViewManager.PDFResult?) {
        guard let result = result else { return }
        
        switch result {
        case .success(let data):
            pdfDataToSave = data
            showingFilePicker = true
        case .failure(let error):
            saveErrorMessage = String(localized: "Failed to generate PDF: \(error.localizedDescription)")
            showingSaveError = true
        }
        
        // Clear the result after handling
        webViewManager.clearPDFResult()
    }
    
    private func generatePDFFilename() -> String {
        let title = webViewManager.pageTitle.isEmpty ? "webpage" : webViewManager.pageTitle
        let cleanTitle = title.replacingOccurrences(of: "[^a-zA-Z0-9\\s-_]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let timestamp = formatter.string(from: Date())
        
        return "\(cleanTitle)_\(timestamp).pdf"
    }
}

// MARK: - Header
private extension WebPagesView {
    var header: some View {
        HStack(spacing: 0) {
            // Left section - Back button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.blue)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            // Center section - Title (perfectly centered)
            HStack {
                Spacer()
                
                VStack(spacing: 2) {
                    Text(String(localized: "Browser"))
                        .font(.system(size: 17, weight: .semibold))
                    
                    if webViewManager.isLoading {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 2)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            // Right section - Print button
            HStack {
                Spacer()
                
                Button {
                    showingPrintOptions = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text(String(localized: "Print"))
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Barra de URL
private extension WebPagesView {
    var urlBar: some View {
        ZStack {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 26, height: 26)
                            
                            Image(systemName: webViewManager.isLoading ? "arrow.clockwise" : "globe")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(webViewManager.isLoading ? 360 : 0))
                                .animation(
                                    .linear(duration: 1).repeatForever(autoreverses: false),
                                    value: webViewManager.isLoading
                                )
                        }
                        
                        TextField(String(localized: "Enter URL or search..."), text: $webViewManager.urlString)
                            .font(.system(size: 15, weight: .medium))
                            .textFieldStyle(.plain)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .onSubmit { webViewManager.loadURL() }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                
                Button {
                    webViewManager.toggleDesktopMode()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: webViewManager.isDesktopMode ? "desktopcomputer" : "iphone")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(webViewManager.isDesktopMode ? String(localized: "Desktop") : String(localized: "Mobile"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(webViewManager.isDesktopMode ? .blue : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(webViewManager.isDesktopMode ? Color.blue.opacity(0.1) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(height: 76)
        .background(Color(.systemGray6))
    }
}

// MARK: - Controles Inferiores (bottomSection = urlBar + bottomNav)
private extension WebPagesView {
    var bottomNav: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                navButton(icon: "chevron.left",
                          title: String(localized: "Back"),
                          enabled: webViewManager.canGoBack) {
                    webViewManager.goBack()
                }
                
                navButton(icon: "chevron.right",
                          title: String(localized: "Forward"),
                          enabled: webViewManager.canGoForward) {
                    webViewManager.goForward()
                }
                
                navButton(icon: "arrow.clockwise",
                          title: String(localized: "Reload"),
                          enabled: true) {
                    webViewManager.reload()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGray6))
    }
    
    @ViewBuilder
    func navButton(
        icon: String,
        title: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .foregroundColor(enabled ? .blue : .gray)
        .disabled(!enabled)
    }
}

#Preview {
    WebPagesView()
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}