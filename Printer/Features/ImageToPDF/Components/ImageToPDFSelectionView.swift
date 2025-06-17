import SwiftUI
import PhotosUI

struct ImageToPDFSelectionView: View {
    @ObservedObject var viewModel: ImageToPDFViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.selectedImages.isEmpty {
                emptyState
            } else {
                populatedState
            }
        }
        .background(Color(.systemBackground))
        .photosPicker(
            isPresented: $viewModel.showingImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 20,
            matching: .images
        )
        .onChange(of: selectedItems) { _, newItems in
            let results = newItems.map { Result<PhotosPickerItem, Error>.success($0) }
            viewModel.addImages(from: results)
            selectedItems = []
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 20)
            
            // Title and description
            VStack(spacing: 12) {
                Text("Image to PDF")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Convert multiple images into a single PDF document")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Add images button
            Button {
                viewModel.showingImagePicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Images")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
    
    private var populatedState: some View {
        VStack(spacing: 0) {
            // Header section
            headerSection
            
            Divider()
            
            // Images list
            imagesList
            
            // Bottom toolbar
            bottomToolbar
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("YOUR IMAGES")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(viewModel.selectedImages.count) image\(viewModel.selectedImages.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Drag to reorder images. They will appear in this order in the PDF.")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var imagesList: some View {
        List {
            ForEach(Array(viewModel.selectedImages.enumerated()), id: \.element.id) { index, imageItem in
                ImageRowView(
                    imageItem: imageItem,
                    index: index
                ) {
                    viewModel.removeImage(at: index)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onMove(perform: viewModel.moveImages)
        }
        .listStyle(.plain)
    }
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                Button {
                    viewModel.showingImagePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                        Text("Add More")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button {
                    viewModel.proceedToSettings()
                } label: {
                    Text("Convert")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(viewModel.selectedImages.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }
}

struct ImageRowView: View {
    let imageItem: ImageItem
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Image thumbnail
            Image(uiImage: imageItem.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(8)
            
            // Image info
            VStack(alignment: .leading, spacing: 2) {
                Text("Image \(index + 1)")
                    .font(.system(size: 16, weight: .medium))
                
                Text("\(Int(imageItem.image.size.width)) × \(Int(imageItem.image.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remove button - más pequeño y más oscuro
            Button {
                onRemove()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray2)) // Más oscuro que systemGray4
                        .frame(width: 20, height: 20) // Más pequeño: de 24 a 20
                    
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .medium)) // Más pequeño: de 12 a 10
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            // Drag handle (solo uno, a la derecha del botón eliminar)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ImageToPDFSelectionView(viewModel: ImageToPDFViewModel())
}
