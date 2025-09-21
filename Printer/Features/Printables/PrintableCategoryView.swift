//
//  PrintableCategoryView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import PDFKit

struct PrintableCategoryView: View {
    let category: PrintableCategory
    let items: [PrintableItem]
    let onPaywallTrigger: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedItem: PrintableItem?
    
    // Ordenar items por nombre
    private var sortedItems: [PrintableItem] {
        return items.sorted { $0.title < $1.title }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Safe area top
            Color(.systemGray6)
                .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
            
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(category.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Invisible button for balance
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .opacity(0)
                }
                .disabled(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            
            // Content grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 14) {
                    ForEach(sortedItems) { item in
                        PrintableCategoryItemCard(
                            item: item,
                            subscriptionManager: subscriptionManager,
                            onTap: { selectedItem = $0 }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGray6))
        }
        .background(Color(.systemGray6))
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedItem) { item in
            PrintableDetailView(
                item: item,
                onPaywallTrigger: {
                    // Cerrar el detalle y mostrar paywall
                    selectedItem = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onPaywallTrigger()
                    }
                }
            )
            .environmentObject(subscriptionManager)
        }
    }
}

struct PrintableCategoryItemCard: View {
    let item: PrintableItem
    let subscriptionManager: SubscriptionManager
    let onTap: (PrintableItem) -> Void
    @State private var thumbnail: UIImage?
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Card background con relieve similar a helpful tips
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color(.systemGray6).opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(0.7, contentMode: .fit)
                    .frame(maxHeight: 200) // Tamaño ligeramente más pequeño
                    .overlay(
                        // Borde superior claro (highlight)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.8),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        // Borde inferior oscuro (sombra interna)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.black.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
                    .overlay(
                        Group {
                            if let thumbnail = thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .interpolation(.high)
                                    .aspectRatio(contentMode: .fill)
                                    .clipped()
                            } else if isLoading {
                                // Loading placeholder
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.blue)
                                    
                                    Text(String(localized: "Loading..."))
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            } else {
                                // Fallback icon when loading failed
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text(item.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 2)
        }
        .onAppear {
            generateThumbnail()
        }
        .onTapGesture {
            onTap(item)
        }
    }
    
    private func generateThumbnail() {
        guard thumbnail == nil else { return }
        
        isLoading = true
        
        let fileName = item.pdfFileName.replacingOccurrences(of: ".pdf", with: "")
        
        if let pdfURL = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let pdfDocument = PDFDocument(url: pdfURL),
                   let firstPage = pdfDocument.page(at: 0) {
                    
                    // Generar thumbnail de alta resolución
                    let pageRect = firstPage.bounds(for: .mediaBox)
                    let scale: CGFloat = 3.0 // Factor de escala para alta resolución
                    let thumbnailSize = CGSize(
                        width: pageRect.width * scale,
                        height: pageRect.height * scale
                    )
                    
                    // Usar UIGraphicsImageRenderer para mejor calidad
                    let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
                    let highQualityThumbnail = renderer.image { context in
                        // Fondo blanco
                        UIColor.white.setFill()
                        context.fill(CGRect(origin: .zero, size: thumbnailSize))
                        
                        // Configurar contexto para alta calidad
                        let cgContext = context.cgContext
                        cgContext.interpolationQuality = .high
                        cgContext.setShouldAntialias(true)
                        cgContext.setShouldSmoothFonts(true)
                        
                        // Transformar y escalar
                        cgContext.translateBy(x: 0, y: thumbnailSize.height)
                        cgContext.scaleBy(x: scale, y: -scale)
                        
                        // Dibujar la página
                        firstPage.draw(with: .mediaBox, to: cgContext)
                    }
                    
                    DispatchQueue.main.async {
                        self.thumbnail = highQualityThumbnail
                        self.isLoading = false
                    }
                } else {
                    // Fallback: crear una imagen de placeholder
                    DispatchQueue.main.async {
                        self.thumbnail = self.createPlaceholderImage()
                        self.isLoading = false
                    }
                }
            }
        } else {
            // Si no existe el archivo PDF, crear placeholder
            DispatchQueue.main.async {
                self.thumbnail = self.createPlaceholderImage()
                self.isLoading = false
            }
        }
    }
    
    private func createPlaceholderImage() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fondo blanco
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Dibujar icono de la categoría
            let iconSize: CGFloat = 60
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            
            UIColor.gray.withAlphaComponent(0.3).setFill()
            context.fill(iconRect)
            
            // Añadir texto del título
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let textRect = CGRect(x: 20, y: size.height - 60, width: size.width - 40, height: 40)
            item.title.draw(in: textRect, withAttributes: attributes)
        }
    }
}

#Preview {
    PrintableCategoryView(
        category: .birthdays, 
        items: [
            PrintableItem(title: "Happy Birthday Card", category: .birthdays),
            PrintableItem(title: "Birthday Wishes", category: .birthdays),
            PrintableItem(title: "Celebration Card", category: .birthdays)
        ],
        onPaywallTrigger: {
            // Empty callback for preview
        }
    )
    .environmentObject(SubscriptionManager())
}