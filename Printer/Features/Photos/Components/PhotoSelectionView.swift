import SwiftUI
import Photos

struct PhotoSelectionView: View {
    @ObservedObject var viewModel: PhotoPrintViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingSelectedPhotosCarousel = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 4)
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingPhotos {
                VStack {
                    Spacer()
                    ProgressView(String(localized: "Loading photos..."))
                        .tint(.blue)
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(viewModel.allPhotos) { photo in
                            PhotoGridItem(
                                photo: photo,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.08)) {
                                        viewModel.selectPhotoForPreview(photo)
                                    }
                                },
                                onToggleSelection: {
                                    withAnimation(.easeInOut(duration: 0.08)) {
                                        viewModel.togglePhotoSelection(photo)
                                    }
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                
                // Bottom toolbar - IMPROVED DESIGN
                if !viewModel.selectedPhotos.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color(.systemGray4))
                        
                        HStack(spacing: 15) {
                            Button(String(localized: "Preview")) {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    showingSelectedPhotosCarousel = true
                                }
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.blue.opacity(0.05))
                                    )
                            )
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.08), value: viewModel.selectedPhotos.count)
                            
                            Button(String(localized: "Print(\(viewModel.selectedPhotos.count))")) {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    viewModel.currentStep = .photoPreview
                                }
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity)
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
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.08), value: viewModel.selectedPhotos.count)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(
                            Rectangle()
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .fullScreenCover(item: $viewModel.selectedPhotoForPreview) { photo in
            PhotoDetailView(photo: photo, viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
        .fullScreenCover(isPresented: $showingSelectedPhotosCarousel) {
            SelectedPhotosCarouselView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
        }
    }
}

struct PhotoGridItem: View {
    let photo: PhotoItem
    let onTap: () -> Void
    let onToggleSelection: () -> Void
    
    @State private var image: UIImage?
    @State private var imageLoadId = UUID()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo thumbnail - MAIN TAP AREA
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.blue)
                        )
                }
            }
            .frame(width: UIScreen.main.bounds.width / 4 - 0.75, height: UIScreen.main.bounds.width / 4 - 0.75)
            .clipped()
            .contentShape(Rectangle()) // EXPLICIT CONTENT SHAPE
            .onTapGesture {
                // Handle tap based on location
                onTap()
            }
            .id(imageLoadId)
            .onAppear {
                loadImageIfNeeded()
            }
            
            // Selection indicator - SEPARATE TAP AREA
            Button(action: onToggleSelection) {
                ZStack {
                    // LARGER TAP TARGET
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40) // Larger tap area
                    
                    // VISUAL INDICATOR
                    Circle()
                        .fill(photo.isSelected ? Color.blue : Color.clear)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 30, height: 30)
                        )
                        .scaleEffect(photo.isSelected ? 1.05 : 1.0)
                    
                    if photo.isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle()) // PREVENT DEFAULT BUTTON BEHAVIOR
            .contentShape(Circle()) // CIRCULAR TAP AREA ONLY
            .frame(width: 40, height: 40) // EXPLICIT FRAME FOR TAP AREA
            .offset(x: -5, y: 5) // POSITION PRECISELY
            .animation(.easeInOut(duration: 0.08), value: photo.isSelected)
            .zIndex(1) // ENSURE IT'S ON TOP
        }
        .animation(.easeInOut(duration: 0.1), value: image != nil)
    }
    
    private func loadImageIfNeeded() {
        guard image == nil else { return }
        
        let targetSize = CGSize(width: 200, height: 200)
        PhotoPrintViewModel().loadImage(for: photo, targetSize: targetSize) { loadedImage in
            withAnimation(.easeIn(duration: 0.1)) {
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoSelectionView(viewModel: PhotoPrintViewModel())
}