import SwiftUI
import Photos
import PhotosUI

struct PhotoPrintView: View {
    @StateObject private var viewModel = PhotoPrintViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.currentStep {
                case .permissionRequest:
                    PhotoPermissionView(viewModel: viewModel)
                case .photoSelection:
                    PhotoSelectionView(viewModel: viewModel)
                case .photoPreview:
                    PhotoPreviewView(viewModel: viewModel)
                }
            }
            .navigationTitle(navigationTitleForCurrentStep())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if viewModel.currentStep != .permissionRequest {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                handleBackNavigation()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.backward")
                                Text("Back")
                            }
                        }
                    } else {
                        Button("Cancel") {
                            withAnimation(.easeOut(duration: 0.2)) {
                                dismiss()
                            }
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .photoSelection && !viewModel.selectedPhotos.isEmpty {
                        Button("Done") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.currentStep = .photoPreview
                            }
                        }
                        .font(.system(size: 17, weight: .medium))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Forces single view on iPad
    }
    
    private func handleBackNavigation() {
        switch viewModel.currentStep {
        case .photoPreview:
            viewModel.currentStep = .photoSelection
        case .photoSelection:
            // Clear selections and go back to main app
            viewModel.selectedPhotos.removeAll()
            viewModel.allPhotos.indices.forEach { index in
                viewModel.allPhotos[index].isSelected = false
            }
            dismiss()
        case .permissionRequest:
            dismiss()
        }
    }
    
    private func navigationTitleForCurrentStep() -> String {
        switch viewModel.currentStep {
        case .permissionRequest:
            return "Photo Print"
        case .photoSelection:
            return "Recents"
        case .photoPreview:
            return "Photo Print"
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoPrintView()
}
