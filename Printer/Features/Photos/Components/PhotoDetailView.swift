import SwiftUI
import Photos

struct PhotoDetailView: View {
    let photo: PhotoItem
    @ObservedObject var viewModel: PhotoPrintViewModel
    @Environment(\.dismiss) var dismiss
    @State private var fullResolutionImage: UIImage?
    @State private var isLoadingFullRes = true
    @State private var showOverlay = true
    @State private var isPhotoSelected: Bool = false
    
    var body: some View {
        ZStack {
            // Main image area (white background) - full screen
            ZStack {
                Color.white
                
                if let image = fullResolutionImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                } else {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        
                        Text("Loading...")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showOverlay.toggle()
                }
            }
            
            // Semi-transparent overlay on top of image
            if showOverlay {
                VStack(spacing: 0) {
                    // Top gray bar with navigation buttons (ADDED TOP MARGIN)
                    HStack {
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                        }
                        .frame(width: 44, height: 44)
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.08)) {
                                isPhotoSelected.toggle()
                                viewModel.togglePhotoSelection(photo)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(isPhotoSelected ? Color.blue : Color.clear)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 26, height: 26)
                                    .scaleEffect(isPhotoSelected ? 1.05 : 1.0)
                                
                                if isPhotoSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(width: 44, height: 44)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60) // INCREASED TOP MARGIN
                    .padding(.bottom, 25)
                    .background(Color.black.opacity(0.6))
                    
                    Spacer()
                    
                    // Bottom gray bar with "Done" text and badge
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Badge with number of selections (left side)
                            if !viewModel.selectedPhotos.isEmpty {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 24, height: 24)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Text("\(viewModel.selectedPhotos.count)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            Button("Done") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if !viewModel.selectedPhotos.isEmpty {
                                        viewModel.currentStep = .photoPreview
                                    }
                                    dismiss()
                                }
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 35)
                    .padding(.bottom, 45)
                    .background(Color.black.opacity(0.6))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            withAnimation(.easeIn(duration: 0.25)) {
                loadFullResolutionImage()
                isPhotoSelected = photo.isSelected
            }
        }
        .onChange(of: photo.isSelected) { newValue in
            withAnimation(.easeInOut(duration: 0.08)) {
                isPhotoSelected = newValue
            }
        }
    }
    
    private func loadFullResolutionImage() {
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        
        viewModel.loadImage(for: photo, targetSize: targetSize) { image in
            withAnimation(.easeIn(duration: 0.15)) {
                self.fullResolutionImage = image
                self.isLoadingFullRes = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoDetailView(photo: PhotoItem(asset: PHAsset()), viewModel: PhotoPrintViewModel())
}
