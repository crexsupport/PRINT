import SwiftUI

struct PDFCompressionIntroView: View {
    @ObservedObject var viewModel: PDFCompressionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section with icon and title
            headerSection
            
            // Features section
            featuresSection
            
            Spacer()
            
            // Single import button
            importSection
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 8)
                
                VStack(spacing: 4) {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    // Compression indicator
                    HStack(spacing: 2) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(.white)
                                .frame(width: 3, height: 3)
                                .scaleEffect(index == 1 ? 0.6 : 1.0)
                        }
                    }
                }
            }
            
            VStack(spacing: 8) {
                Text("Compress PDF")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Get the same PDF quality but less file-size")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 15) {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 8, height: 8)
                    
                    Text(feature.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }
    
    private var importSection: some View {
        VStack(spacing: 20) {
            // Single import button
            Button {
                viewModel.selectDocumentFromFiles()
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    
                    Text("Select PDF File")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
    
    private let features = [
        (title: "Resize PDF files", icon: "arrow.up.and.down.square"),
        (title: "Optimize for web view or printing", icon: "globe"),
        (title: "Reduce file size up to 99%", icon: "chart.line.downtrend.xyaxis"),
        (title: "3 compression levels", icon: "slider.horizontal.3")
    ]
}

struct ImportButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PDFCompressionIntroView(viewModel: PDFCompressionViewModel())
}
