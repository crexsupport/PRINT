import SwiftUI
import Photos

struct PhotoPermissionView: View {
    @ObservedObject var viewModel: PhotoPrintViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 24) {
                Spacer()
                
                Text(String(localized: "Allow Printer to access your gallery in \"Settings > Privacy > Photos\""))
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Button(String(localized: "Settings")) {
                    viewModel.openSettings()
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                
                Spacer()
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.checkPhotoLibraryPermission()
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoPermissionView(viewModel: PhotoPrintViewModel())
}