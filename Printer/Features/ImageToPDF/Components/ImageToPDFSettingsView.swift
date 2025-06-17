import SwiftUI

struct ImageToPDFSettingsView: View {
    @ObservedObject var viewModel: ImageToPDFViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content with scroll
            ScrollView {
                VStack(spacing: 0) {
                    // Images summary
                    imagesSummarySection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Orientation section
                    orientationSection
                    
                    // Bottom padding to avoid floating button overlap
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.top, 20)
            }
            
            // Floating convert button
            floatingConvertButton
        }
        .background(Color(.systemBackground))
    }
    
    private var imagesSummarySection: some View {
        VStack(spacing: 12) {
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
            
            // Images preview row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.selectedImages.enumerated()), id: \.element.id) { index, imageItem in
                        VStack(spacing: 4) {
                            Image(uiImage: imageItem.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    private var orientationSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("ORIENTATION")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Orientation options
            VStack(spacing: 16) {
                // Toggle-style selector
                HStack(spacing: 12) {
                    ForEach(PDFOrientation.allCases, id: \.self) { orientation in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedOrientation = orientation
                            }
                        } label: {
                            ModernOrientationOptionView(
                                orientation: orientation,
                                isSelected: viewModel.selectedOrientation == orientation
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                
                // Visual preview of selected orientation
                OrientationPreviewView(orientation: viewModel.selectedOrientation)
            }
            .padding(.horizontal, 20)
            
            // Info section about PDF settings
            VStack(spacing: 12) {
                HStack {
                    Text("PDF DETAILS")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Format: A4 (210 × 297 mm)")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Images will be centered and scaled to fit")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "aspectratio")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Aspect ratio preserved automatically")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    private var convertButton: some View {
        VStack(spacing: 16) {
            Divider()
            
            Button {
                viewModel.generatePDF()
            } label: {
                Text("Convert to PDF")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
    
    private var floatingConvertButton: some View {
        VStack(spacing: 0) {
            // Gradient overlay to blend with content
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(.systemBackground).opacity(0), location: 0),
                    .init(color: Color(.systemBackground).opacity(0.8), location: 0.3),
                    .init(color: Color(.systemBackground), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            // Button container
            VStack(spacing: 0) {
                Button {
                    viewModel.generatePDF()
                } label: {
                    Text("Convert to PDF")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area bottom padding
            }
            .background(Color(.systemBackground))
        }
    }
}

struct ModernOrientationOptionView: View {
    let orientation: PDFOrientation
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: orientation.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(height: 30)
            
            // Title - más grande y visible
            Text(orientation.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .blue : .primary)
            
            // Description - más pequeña pero legible
            Text(orientation.description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Selection indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)
                
                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct OrientationPreviewView: View {
    let orientation: PDFOrientation
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("PREVIEW")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("A4 Paper")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 3D-style paper preview
            ZStack {
                // Shadow layer
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.1))
                    .frame(
                        width: orientation == .portrait ? 120 : 160,
                        height: orientation == .portrait ? 160 : 120
                    )
                    .offset(x: 2, y: 2)
                
                // Main paper
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(
                        width: orientation == .portrait ? 120 : 160,
                        height: orientation == .portrait ? 160 : 120
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                // Sample content lines
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(
                                width: orientation == .portrait ? 80 : 120,
                                height: 2
                            )
                    }
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: orientation)
            
            // Orientation info
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Width")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(orientation == .portrait ? "210mm" : "297mm")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Image(systemName: "arrow.left.and.right")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                VStack(spacing: 4) {
                    Text("Height")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(orientation == .portrait ? "297mm" : "210mm")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

#Preview {
    ImageToPDFSettingsView(viewModel: ImageToPDFViewModel())
}
