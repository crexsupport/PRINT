import SwiftUI
import Photos

struct SelectedPhotosCarouselView: View {
    @ObservedObject var viewModel: PhotoPrintViewModel
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex = 0
    @State private var showOverlay = true
    @State private var localSelectedPhotos: [PhotoItem] = []
    
    var body: some View {
        ZStack {
            // Main carousel area
            if !localSelectedPhotos.isEmpty {
                // Carousel of selected photos
                TabView(selection: $currentIndex) {
                    ForEach(0..<localSelectedPhotos.count, id: \.self) { index in
                        SelectedPhotoCarouselItem(photo: localSelectedPhotos[index], viewModel: viewModel)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOverlay.toggle()
                    }
                }
                .id(localSelectedPhotos.count) // Force refresh when count changes
            } else {
                // Empty state
                VStack {
                    Text("No photos selected")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
            
            // Overlay with same design as PhotoDetailView
            if showOverlay {
                VStack(spacing: 0) {
                    // Top gray bar with navigation buttons (same as PhotoDetailView)
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                        }
                        .frame(width: 44, height: 44)
                        
                        Spacer()
                        
                        Button {
                            removeCurrentPhoto()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.clear)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                    .padding(.bottom, 25)
                    .background(Color.black.opacity(0.6))
                    
                    Spacer()
                    
                    // Bottom gray bar with navigation and done button (LARGER)
                    HStack {
                        // Navigation controls
                        HStack(spacing: 20) {
                            Button(action: {
                                if currentIndex > 0 {
                                    withAnimation {
                                        currentIndex -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentIndex > 0 ? .white : .gray)
                            }
                            .disabled(currentIndex == 0)
                            
                            Text("\(currentIndex + 1) / \(localSelectedPhotos.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                if currentIndex < localSelectedPhotos.count - 1 {
                                    withAnimation {
                                        currentIndex += 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentIndex < localSelectedPhotos.count - 1 ? .white : .gray)
                            }
                            .disabled(currentIndex >= localSelectedPhotos.count - 1)
                        }
                        
                        Spacer()
                        
                        // Done button with badge (same as PhotoDetailView)
                        HStack(spacing: 8) {
                            // Badge with number of selections (left side)
                            if !localSelectedPhotos.isEmpty {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 20, height: 20)
                                    
                                    Text("\(localSelectedPhotos.count)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Button("Done") {
                                if !localSelectedPhotos.isEmpty {
                                    viewModel.currentStep = .photoPreview
                                }
                                dismiss()
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 35) // Increased from 25
                    .padding(.bottom, 45) // Increased from 30
                    .background(Color.black.opacity(0.6))
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            // Initialize local state with viewModel data
            localSelectedPhotos = viewModel.selectedPhotos
            // Ensure currentIndex is within bounds
            if currentIndex >= localSelectedPhotos.count {
                currentIndex = max(0, localSelectedPhotos.count - 1)
            }
        }
        .onChange(of: viewModel.selectedPhotos) { newSelectedPhotos in
            // Update local state when viewModel changes
            localSelectedPhotos = newSelectedPhotos
            
            // Adjust currentIndex if needed
            if currentIndex >= localSelectedPhotos.count {
                currentIndex = max(0, localSelectedPhotos.count - 1)
            }
        }
    }
    
    private func removeCurrentPhoto() {
        guard currentIndex < localSelectedPhotos.count else { return }
        
        let photoToRemove = localSelectedPhotos[currentIndex]
        
        // Remove from viewModel (this will trigger onChange)
        viewModel.togglePhotoSelection(photoToRemove)
        
        // Immediately update local state for instant UI feedback
        localSelectedPhotos.removeAll { $0.id == photoToRemove.id }
        
        // Adjust currentIndex if needed
        if localSelectedPhotos.isEmpty {
            dismiss()
        } else if currentIndex >= localSelectedPhotos.count {
            withAnimation {
                currentIndex = max(0, localSelectedPhotos.count - 1)
            }
        }
    }
}

struct SelectedPhotoCarouselItem: View {
    let photo: PhotoItem
    @ObservedObject var viewModel: PhotoPrintViewModel
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            Color.white
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
            } else {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.gray)
                    
                    Text("Loading...")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        viewModel.loadImage(for: photo, targetSize: targetSize) { loadedImage in
            self.image = loadedImage
        }
    }
}

// MARK: - Preview
#Preview {
    SelectedPhotosCarouselView(viewModel: PhotoPrintViewModel())
}
