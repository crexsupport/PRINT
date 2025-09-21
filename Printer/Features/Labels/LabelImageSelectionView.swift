//
//  LabelImageSelectionView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import Photos
import PhotosUI

struct LabelImageSelectionView: View {
    let format: LabelFormat
    let onPaywallTrigger: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @State private var selectedImage: UIImage?
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showPermissionAlert = false
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 0) {
            safeAreaTopView
            headerView
            contentView
        }
        .background(Color(.systemGray6))
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            checkPhotoPermission()
        }
        .onChange(of: photoPickerItems) { _, newItems in
            loadImage(from: newItems)
        }
        .alert("Photo Permission Denied", isPresented: $showPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable photo access in Settings to select images for your labels.", 
                 comment: "Message explaining how to enable photo access")
        }
    }
    
    private var safeAreaTopView: some View {
        Color(.systemGray6)
            .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("Select Image")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            printButtonView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    private var printButtonView: some View {
        Group {
            if selectedImage != nil {
                Button(action: {
                    handlePrintTap()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Print")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.3, green: 0.6, blue: 0.95),
                                Color(red: 0.15, green: 0.4, blue: 0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
            } else {
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Print")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .opacity(0)
                }
                .disabled(true)
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            formatInfoCard
            imageSelectionSection
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private var formatInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Label Format")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Label sheet preview with selected image
            VStack(spacing: 12) {
                LabelSheetPreview(format: format, selectedImage: selectedImage)
                    .frame(height: 160)
                
                VStack(alignment: .center, spacing: 4) {
                    Text(format.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Select 1 image to repeat \(format.labelsPerSheet) times")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 16) {
            if authorizationStatus == .authorized || authorizationStatus == .limited {
                photoPickerView
                selectedImageView
            } else {
                permissionRequestView
            }
        }
    }
    
    private var photoPickerView: some View {
        PhotosPicker(
            selection: $photoPickerItems,
            maxSelectionCount: 1,
            matching: .images
        ) {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                Text("Select Image from Photos")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Choose 1 image to repeat on all labels")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
        }
        .padding(.horizontal, 16)
    }
    
    private var selectedImageView: some View {
        Group {
            if let selectedImage = selectedImage {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Selected Image")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            self.selectedImage = nil
                            photoPickerItems = []
                        }) {
                            Text("Change")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var permissionRequestView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Photo Access Required")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("To create labels with your photos, we need access to your photo library.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: {
                requestPhotoPermission()
            }) {
                Text("Allow Photo Access")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .cornerRadius(22)
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 16)
    }
    
    private func checkPhotoPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    private func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                authorizationStatus = status
                if status == .denied {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func loadImage(from items: [PhotosPickerItem]) {
        guard let item = items.first else { return }
        
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        selectedImage = image
                    }
                }
            case .failure(let error):
                print("Error loading image: \(error)")
            }
        }
    }
    
    private func handlePrintTap() {
        // Usar callback para triggerear paywall desde el padre
        if subscriptionManager.isSubscribed {
            printLabels()
        } else {
            onPaywallTrigger()
        }
    }
    
    private func printLabels() {
        // Create label sheet with selected image
        guard let labelSheet = createLabelSheet() else { return }
        
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = "Label Print - \(format.title)"
        
        printController.printInfo = printInfo
        printController.printingItem = labelSheet
        
        printController.present(animated: true) { (controller, completed, error) in
            if let error = error {
                print("Print error: \(error.localizedDescription)")
            } else if completed {
                print("Labels printed successfully")
            }
        }
    }
    
    private func createLabelSheet() -> UIImage? {
        guard let selectedImage = selectedImage else { return nil }
        
        let pageSize = CGSize(width: 612, height: 792) // US Letter size in points
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            // Calculate label dimensions and positions con más realismo
            let margin: CGFloat = 36 // 0.5 inch margins
            let spacing: CGFloat = 12 // Espacio entre labels
            let availableWidth = pageSize.width - (2 * margin)
            let availableHeight = pageSize.height - (2 * margin)
            
            let totalHorizontalSpacing = CGFloat(format.gridColumns - 1) * spacing
            let totalVerticalSpacing = CGFloat(format.gridRows - 1) * spacing
            
            let labelWidth = (availableWidth - totalHorizontalSpacing) / CGFloat(format.gridColumns)
            let labelHeight = (availableHeight - totalVerticalSpacing) / CGFloat(format.gridRows)
            
            // Configurar contexto para alta calidad
            let cgContext = context.cgContext
            cgContext.interpolationQuality = .high
            cgContext.setShouldAntialias(true)
            cgContext.setShouldSmoothFonts(true)
            
            // Draw labels - repeat the same image with high quality
            for row in 0..<format.gridRows {
                for column in 0..<format.gridColumns {
                    let x = margin + (CGFloat(column) * (labelWidth + spacing))
                    let y = margin + (CGFloat(row) * (labelHeight + spacing))
                    
                    let labelRect = CGRect(
                        x: x,
                        y: y,
                        width: labelWidth,
                        height: labelHeight
                    )
                    
                    // Calcular el rect de la imagen manteniendo aspect ratio
                    let imageSize = selectedImage.size
                    let imageAspectRatio = imageSize.width / imageSize.height
                    let labelAspectRatio = labelWidth / labelHeight
                    
                    let imageRect: CGRect
                    if imageAspectRatio > labelAspectRatio {
                        // La imagen es más ancha, ajustar por altura
                        let scaledWidth = labelHeight * imageAspectRatio
                        imageRect = CGRect(
                            x: x + (labelWidth - scaledWidth) / 2,
                            y: y,
                            width: scaledWidth,
                            height: labelHeight
                        )
                    } else {
                        // La imagen es más alta, ajustar por ancho
                        let scaledHeight = labelWidth / imageAspectRatio
                        imageRect = CGRect(
                            x: x,
                            y: y + (labelHeight - scaledHeight) / 2,
                            width: labelWidth,
                            height: scaledHeight
                        )
                    }
                    
                    // Crear clip path para mantener bordes dentro del label
                    cgContext.saveGState()
                    cgContext.addRect(labelRect)
                    cgContext.clip()
                    
                    // Dibujar imagen con alta calidad
                    selectedImage.draw(in: imageRect)
                    
                    cgContext.restoreGState()
                }
            }
        }
    }
}

// New preview component for the label sheet
struct LabelSheetPreview: View {
    let format: LabelFormat
    let selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 8) {
            // Usar EXACTAMENTE la misma estructura que LabelFormatPreview
            VStack(spacing: 4) {
                ForEach(0..<format.gridRows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<format.gridColumns, id: \.self) { column in
                            ZStack {
                                // Fondo del contenedor
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedImage != nil ? Color.white : Color(.systemGray4))
                                    .aspectRatio(1.4, contentMode: .fit)
                                
                                // Imagen con clipping forzado
                                if let selectedImage = selectedImage {
                                    RoundedRectangle(cornerRadius: 4)
                                        .aspectRatio(1.4, contentMode: .fit)
                                        .overlay(
                                            Image(uiImage: selectedImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        .clipped()
                                }
                                
                                // Borde encima de todo
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .aspectRatio(1.4, contentMode: .fit)
                            }
                        }
                    }
                }
            }
            .frame(height: 120) // MISMA altura que LabelFormatPreview
            .frame(maxWidth: .infinity)
            .padding(12) // Padding para simular la hoja
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct DimensionCalculations {
    let margin: CGFloat
    let spacing: CGFloat
    let labelWidth: CGFloat
    let labelHeight: CGFloat
}

#Preview {
    LabelImageSelectionView(
        format: LabelFormat.allFormats[0],
        onPaywallTrigger: {
            // Empty callback for preview
        }
    )
    .environmentObject(SubscriptionManager())
    .environmentObject(PaywallManager())
}