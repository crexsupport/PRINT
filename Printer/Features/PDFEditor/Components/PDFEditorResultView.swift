import SwiftUI

struct PDFEditorResultView: View {
    @ObservedObject var viewModel: PDFEditorViewModel
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    @State private var showingLocalPaywall = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Success header
            //successHeaderSection
            
            // Document preview section - ocupa todo el espacio restante
            documentPreviewSection
            
            // Bottom buttons - fijos al final
            bottomButtons
        }
        .background(Color.white)
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $showingLocalPaywall) {
            PaywallView(onDismiss: {
                showingLocalPaywall = false
            })
            .environmentObject(subscriptionManager)
            .interactiveDismissDisabled(true)
        }
    }
    
    private var successHeaderSection: some View {
        VStack(spacing: 16) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Success text
            VStack(spacing: 6) {
                Text("Pages Deleted Successfully")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Removed \(viewModel.selectedPagesCount) page\(viewModel.selectedPagesCount == 1 ? "" : "s") from your PDF")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .background(Color.white)
    }
    
    private var documentPreviewSection: some View {
        VStack(spacing: 0) {
            // Document header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR EDITED PDF")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("Document Preview")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // PDF badge
                HStack(spacing: 6) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("PDF")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .background(Color.white)
            
            // PDF viewer que ocupa todo el espacio disponible
            if let url = viewModel.processedDocumentURL {
                PDFKitView(url: url, configuration: .pdfEditorResult)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.05))
                    .clipped()
            } else {
                // Fallback
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Preview Unavailable")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
            }
        }
        .frame(maxHeight: .infinity) // Permite que esta sección crezca
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Primary print button
            Button {
                handlePrintAction()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "printer.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Print Document")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            // Secondary edit another button
            Button {
                viewModel.resetToFileSelection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    Text("Edit Another PDF")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue.opacity(0.05))
                        )
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 34) // Safe area
        .background(Color.white)
        .frame(maxWidth: .infinity)
    }
    
    private func handlePrintAction() {
        if subscriptionManager.isSubscribed {
            if let url = viewModel.processedDocumentURL {
                printDocument(url: url)
            }
        } else {
            showingLocalPaywall = true
        }
    }
    
    private func printDocument(url: URL) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Edited PDF"
        
        printController.printInfo = printInfo
        printController.printingItem = url
        
        printController.present(animated: true)
    }
}

// MARK: - Supporting Views
struct PDFEditorStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    PDFEditorResultView(viewModel: PDFEditorViewModel())
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}
