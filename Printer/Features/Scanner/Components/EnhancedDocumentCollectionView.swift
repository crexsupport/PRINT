//
//  EnhancedDocumentCollectionView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

struct EnhancedDocumentCollectionView: View {
    @Binding var images: [UIImage]
    let onSave: () -> Void
    let onAddMore: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                DocumentReviewHeader(
                    onBack: { dismiss() },
                    onShare: { showingShareSheet = true }
                )
                
                if !images.isEmpty {
                    DocumentViewer(
                        images: images,
                        currentPage: $currentPage,
                        onDelete: { showingDeleteAlert = true }
                    )
                    
                    Spacer()
                    
                    DocumentActionButtons(
                        imageCount: images.count,
                        onAddMore: onAddMore,
                        onPrint: printDocuments
                    )
                } else {
                    DocumentEmptyState(onStartScanning: onAddMore)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                ActivityViewController(activityItems: images)
            }
            .alert("Delete Document", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteCurrentDocument()
                }
            } message: {
                Text("Are you sure you want to delete this document?")
            }
        }
    }
    
    private func printDocuments() {
        guard UIPrintInteractionController.isPrintingAvailable else {
            print("Printing is not available")
            return
        }
        
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .photo
        printInfo.jobName = "Scanned Documents"
        printInfo.duplex = .none
        
        printController.printInfo = printInfo
        printController.printingItems = images
        
        printController.present(animated: true) { (controller, completed, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Print error: \(error.localizedDescription)")
                }
                if completed {
                    self.onSave()
                }
            }
        }
    }
    
    private func deleteCurrentDocument() {
        guard currentPage < images.count else { return }
        
        images.remove(at: currentPage)
        
        // Adjust current page if necessary
        if currentPage >= images.count && currentPage > 0 {
            currentPage = images.count - 1
        }
        
        // If no documents left, dismiss the view
        if images.isEmpty {
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct DocumentReviewHeader: View {
    let onBack: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("Document Review")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct DocumentViewer: View {
    let images: [UIImage]
    @Binding var currentPage: Int
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            // Document image with delete button overlay
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<images.count, id: \.self) { index in
                        DocumentPage(image: images[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Delete button positioned over the document
                VStack {
                    HStack {
                        DeleteDocumentButton(onDelete: onDelete)
                            .padding(.leading, 30)
                        Spacer()
                    }
                    .padding(.top, 30)
                    Spacer()
                }
            }
            
            // Page navigation
            DocumentPageIndicator(
                currentPage: $currentPage,
                totalPages: images.count
            )
        }
    }
}

struct DocumentPage: View {
    let image: UIImage
    
    var body: some View {
        ZStack {
            Color.white
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(20)
        }
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
    }
}

struct DeleteDocumentButton: View {
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onDelete) {
            Image(systemName: "minus")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.gray.opacity(0.8)))
        }
    }
}

struct DocumentPageIndicator: View {
    @Binding var currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack {
            Button(action: {
                if currentPage > 0 {
                    withAnimation {
                        currentPage -= 1
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(currentPage > 0 ? .primary : .gray)
                    .padding(8)
                    .background(Circle().fill(Color.gray.opacity(0.2)))
            }
            .disabled(currentPage == 0)
            
            Spacer()
            
            Text("\(currentPage + 1) / \(totalPages)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                )
            
            Spacer()
            
            Button(action: {
                if currentPage < totalPages - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(currentPage < totalPages - 1 ? .primary : .gray)
                    .padding(8)
                    .background(Circle().fill(Color.gray.opacity(0.2)))
            }
            .disabled(currentPage >= totalPages - 1)
        }
        .padding(.horizontal, 40)
    }
}

struct DocumentActionButtons: View {
    let imageCount: Int
    let onAddMore: () -> Void
    let onPrint: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button("Add More") {
                onAddMore()
            }
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
            
            Button("Print(\(imageCount))") {
                onPrint()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
            )
        }
        .padding()
    }
}

struct DocumentEmptyState: View {
    let onStartScanning: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No documents scanned")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Capture some documents to see them here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Scanning") {
                onStartScanning()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(Capsule())
        }
        .padding()
    }
}
