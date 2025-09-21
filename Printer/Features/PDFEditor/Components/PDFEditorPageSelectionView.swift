import SwiftUI

struct PDFEditorPageSelectionView: View {
    @ObservedObject var viewModel: PDFEditorViewModel
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    @State private var showingLocalPaywall = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // File info section
            fileInfoSection
            
            Divider()
                .padding(.horizontal)
            
            // Instructions
            instructionsSection
            
            // Pages grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, pageItem in
                        PDFPageThumbnailView(
                            pageItem: pageItem,
                            isSelected: pageItem.isSelected
                        ) {
                            viewModel.togglePageSelection(at: index)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120) // Increased space for bottom toolbar
            }
            
            // Fixed bottom toolbar with proper spacing
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    // Select/Deselect all
                    Button {
                        if viewModel.selectedPagesCount == viewModel.pages.count {
                            viewModel.deselectAllPages()
                        } else {
                            viewModel.selectAllPages()
                        }
                    } label: {
                        Text(viewModel.selectedPagesCount == viewModel.pages.count ? String(localized: "Deselect All") : String(localized: "Select All"))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    // Delete button with paywall check
                    Button {
                        handleDeleteAction()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                            Text(String(localized: "Delete (\(viewModel.selectedPagesCount))"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16) // Reduced from 20 to 16
                        .padding(.vertical, 10) // Reduced from 12 to 10
                        .background(viewModel.canDeletePages ? Color.red : Color.gray)
                        .cornerRadius(8)
                    }
                    .disabled(!viewModel.canDeletePages)
                }
                .padding(.horizontal, 20) // Consistent horizontal padding
                .padding(.vertical, 16) // Proper vertical padding
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $showingLocalPaywall) {
            PaywallView(onDismiss: {
                showingLocalPaywall = false
            })
            .environmentObject(subscriptionManager)
            .interactiveDismissDisabled(true) // Disable swipe to dismiss
        }
    }
    
    private func handleDeleteAction() {
        if subscriptionManager.isSubscribed {
            // User is subscribed, proceed with deleting pages
            viewModel.deleteSelectedPages()
        } else {
            // User is not subscribed, show local paywall
            showingLocalPaywall = true
        }
    }
    
    private var fileInfoSection: some View {
        VStack(spacing: 8) {
            Text(String(localized: "YOUR FILE"))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedDocument?.lastPathComponent ?? "Unknown")
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                    
                    Text(String(localized: "\(viewModel.pages.count) pages"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var instructionsSection: some View {
        VStack(spacing: 8) {
            Text(String(localized: "CHOOSE UNWANTED PAGES"))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(String(localized: "Tap pages to select them for deletion. Selected pages will be highlighted."))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct PDFPageThumbnailView: View {
    let pageItem: PDFPageItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.red : Color.clear, lineWidth: 3)
                    )
                
                if let thumbnail = pageItem.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .cornerRadius(6)
                        .opacity(isSelected ? 0.6 : 1.0)
                } else {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 50, y: -50)
                }
            }
            
            Text("\(pageItem.pageNumber)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .red : .primary)
        }
        .onTapGesture {
            onTap()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    PDFEditorPageSelectionView(viewModel: PDFEditorViewModel())
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}