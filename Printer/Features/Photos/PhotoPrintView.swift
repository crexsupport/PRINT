//
//  PhotoPrintView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import Photos
import PhotosUI

struct PhotoPrintView: View {
    @StateObject private var viewModel = PhotoPrintViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // NUEVA PROPIEDAD: Para saber si se abrió desde el grid (tiene botón back)
    let showBackButton: Bool
    
    // NUEVO INICIALIZADOR
    init(showBackButton: Bool = true) {
        self.showBackButton = showBackButton
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // CONDICIONAL: Solo mostrar header con botón back si viene del grid
                if showBackButton {
                    // Custom header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("Print Photos")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Button("Back") {
                            // Empty action
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))
                }
                
                // Content based on current state - CORREGIDO
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
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Forces single view on iPad
        .onAppear {
            // CORREGIDO: Usar el método correcto
            viewModel.checkPhotoLibraryPermission()
        }
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
