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
                title: Text("Print Options"),
                message: Text("Choose how to print this web page"),
                buttons: [
                    .default(Text("Print Current Page")) { webViewManager.printCurrentPage() },
                    .default(Text("Print Full Website")) { webViewManager.printFullWebsite() },
                    .default(Text("Save as PDF"))        { webViewManager.saveAsPDF() },
                    .cancel(Text("Cancel"))
                ]
            )
        }
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
                    Text("Browser")
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
                        Text("Print")
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
                        
                        TextField("Enter URL or search...", text: $webViewManager.urlString)
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
                        
                        Text(webViewManager.isDesktopMode ? "Desktop" : "Mobile")
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
                          title: "Back",
                          enabled: webViewManager.canGoBack) {
                    webViewManager.goBack()
                }
                
                navButton(icon: "chevron.right",
                          title: "Forward",
                          enabled: webViewManager.canGoForward) {
                    webViewManager.goForward()
                }
                
                navButton(icon: "arrow.clockwise",
                          title: "Reload",
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
}