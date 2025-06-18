import SwiftUI

struct PhotoPreviewView: View {
    @ObservedObject var viewModel: PhotoPrintViewModel
    @State private var currentIndex = 0
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    @State private var showingLocalPaywall = false
    
    private var selectedPhotos: [PhotoItem] {
        viewModel.allPhotos.filter { $0.isSelected }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo viewer as document pages
            photoViewerSection
            
            // Controls
            controlsSection
        }
        .onAppear {
            if currentIndex >= selectedPhotos.count {
                currentIndex = max(0, selectedPhotos.count - 1)
            }
        }
        .onChange(of: selectedPhotos.count) { oldValue, newValue in
            if currentIndex >= newValue {
                currentIndex = max(0, newValue - 1)
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
    
    private var photoViewerSection: some View {
        Group {
            if !selectedPhotos.isEmpty {
                photoTabView
            } else {
                emptyStateView
            }
        }
    }
    
    private var photoTabView: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(selectedPhotos.enumerated()), id: \.element.id) { index, photo in
                PhotoDocumentPageView(
                    photo: photo,
                    pageNumber: index + 1,
                    totalPages: selectedPhotos.count,
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            deletePhoto(photo: photo)
                        }
                    }
                )
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
        .id(selectedPhotos.count) // Force refresh when count changes
    }
    
    private var emptyStateView: some View {
        VStack {
            Text("No photos selected")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            navigationControls
            actionButtons
        }
        .padding(.bottom, 30)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
    }
    
    private var navigationControls: some View {
        HStack(spacing: 30) {
            // Previous button
            Button(action: {
                if currentIndex > 0 {
                    withAnimation(.easeInOut(duration: 0.08)) {
                        currentIndex -= 1
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentIndex > 0 ? .primary : .gray)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            )
            .disabled(currentIndex == 0)
            
            Spacer()
            
            // Page indicator dots
            pageIndicator
            
            Spacer()
            
            // Next button
            Button(action: {
                if currentIndex < selectedPhotos.count - 1 {
                    withAnimation(.easeInOut(duration: 0.08)) {
                        currentIndex += 1
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentIndex < selectedPhotos.count - 1 ? .primary : .gray)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            )
            .disabled(currentIndex >= selectedPhotos.count - 1)
        }
        .padding(.horizontal, 30)
        .padding(.top, 10)
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<selectedPhotos.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentIndex ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.08), value: currentIndex)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 15) {
            // Add More button
            Button("Add More") {
                withAnimation(.easeInOut(duration: 0.1)) {
                    viewModel.currentStep = .photoSelection
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.05))
                    )
            )
            
            Button("Print (\(selectedPhotos.count))") {
                withAnimation(.easeInOut(duration: 0.1)) {
                    handlePrintAction()
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func handlePrintAction() {
        if subscriptionManager.isSubscribed {
            // User is subscribed, proceed with printing
            viewModel.printPhotos()
        } else {
            // User is not subscribed, show local paywall
            showingLocalPaywall = true
        }
    }
    
    private func deletePhoto(photo: PhotoItem) {
        // Get the current photo before deletion for navigation adjustment
        let photosBeforeDeletion = selectedPhotos
        let currentPhoto = currentIndex < photosBeforeDeletion.count ? photosBeforeDeletion[currentIndex] : nil
        
        // Remove the specific photo from viewModel
        viewModel.togglePhotoSelection(photo)
        
        // Update the selection after deletion
        let photosAfterDeletion = selectedPhotos
        
        // Handle navigation after deletion
        if photosAfterDeletion.isEmpty {
            withAnimation(.easeOut(duration: 0.1)) {
                viewModel.currentStep = .photoSelection
            }
        } else {
            // If we deleted the photo we were viewing, adjust the index
            if let currentPhoto = currentPhoto, currentPhoto.id == photo.id {
                // If we deleted the current photo, stay at the same index or move back if at the end
                let newIndex = min(currentIndex, photosAfterDeletion.count - 1)
                withAnimation(.easeInOut(duration: 0.1)) {
                    currentIndex = max(0, newIndex)
                }
            } else {
                // If we deleted a different photo, try to maintain the current photo in view
                if let currentPhoto = currentPhoto,
                   let newIndex = photosAfterDeletion.firstIndex(where: { $0.id == currentPhoto.id }) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        currentIndex = newIndex
                    }
                } else {
                    // Fallback: just ensure we're within bounds
                    let newIndex = min(currentIndex, photosAfterDeletion.count - 1)
                    withAnimation(.easeInOut(duration: 0.1)) {
                        currentIndex = max(0, newIndex)
                    }
                }
            }
        }
    }
}

struct PhotoDocumentPageView: View {
    let photo: PhotoItem
    let pageNumber: Int
    let totalPages: Int
    let onDelete: () -> Void
    @State private var image: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Document container
            ZStack(alignment: .topLeading) {
                // Subtle paper shadow
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.08))
                    .offset(x: 3, y: 3)
                
                // Main paper document
                photoContentView
                
                // Delete button
                deleteButton
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadImage()
        }
    }
    
    private var photoContentView: some View {
        VStack(spacing: 0) {
            // Photo content area
            ZStack {
                Color.white
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(30)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.blue)
                        Text("Loading...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
    
    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "minus")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(Color(.systemGray))
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                )
        }
        .offset(x: 12, y: 12)
    }
    
    private func loadImage() {
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        
        let tempViewModel = PhotoPrintViewModel()
        tempViewModel.loadImage(for: photo, targetSize: targetSize) { loadedImage in
            withAnimation(.easeIn(duration: 0.1)) {
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Preview
struct PhotoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPreviewView(viewModel: PhotoPrintViewModel())
            .environmentObject(SubscriptionManager())
            .environmentObject(PaywallManager())
    }
}
