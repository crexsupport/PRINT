import SwiftUI
import Photos

struct PhotoPermissionView: View {
    @ObservedObject var viewModel: PhotoPrintViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with printer illustration
            VStack(spacing: 20) {
                Spacer()
                
                // Printer illustration (similar to the screenshot)
                VStack(spacing: 15) {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .offset(x: 20, y: -20)
                }
                .padding(.bottom, 30)
                
                VStack(spacing: 15) {
                    Text("Unlock all the")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("features of your printer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.primary)
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            
            // Bottom section with permission request
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("Printer wants to access")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("your photo library")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("To print photos, access to the")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("photo library is required.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                
                // Photo grid preview (small sample)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4), spacing: 2) {
                    ForEach(0..<8, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .frame(height: 120)
                .clipped()
                .padding(.horizontal, 40)
                
                VStack(spacing: 8) {
                    Text("14,187 photos, 897 videos")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Photos may contain data")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("associated with location, information")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Different buttons based on permission status
                VStack(spacing: 15) {
                    if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                        // Show settings redirect when permission is denied
                        VStack(spacing: 15) {
                            Text("Allow Printer to access your gallery in \"Settings > Privacy > Photos\"")
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button("Open Settings") {
                                viewModel.handlePermissionDenied()
                            }
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.clear)
                        }
                    } else {
                        // Show permission request options when not determined
                        Button("Limited Access...") {
                            viewModel.requestPhotoLibraryPermission()
                        }
                        .font(.body)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.clear)
                        
                        Button("Allow Full Access") {
                            viewModel.requestPhotoLibraryPermission()
                        }
                        .font(.body)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.clear)
                        
                        Button("Don't Allow") {
                            // Handle no permission - could dismiss the view or show alternative
                        }
                        .font(.body)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.clear)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(
                Color.black.opacity(0.85)
                    .ignoresSafeArea(.all)
            )
        }
        .background(Color(.systemBackground))
        .onAppear {
            // Re-check permission status when view appears (in case user changed it in Settings)
            viewModel.checkPhotoLibraryPermission()
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoPermissionView(viewModel: PhotoPrintViewModel())
}
