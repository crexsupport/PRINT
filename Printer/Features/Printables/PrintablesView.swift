//
//  PrintablesView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import PDFKit

struct PrintablesView: View {
    @State private var selectedCategory: PrintableCategory = .all
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    @StateObject private var printablesManager = PrintablesManager()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PrintableItem?
    
    let showHeader: Bool
    
    init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
    
    private var filteredItems: [PrintableItem] {
        return printablesManager.printables(for: selectedCategory)
    }
    
    private var categoriesWithCount: [(PrintableCategory, Int)] {
        PrintableCategory.allCases.map { category in
            let count = printablesManager.printables(for: category).count
            return (category, count)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header condicional
            if showHeader {
                // Safe area top
                Color(.systemGray6)
                    .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                
                // Header content
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "Printables"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Invisible button to balance the layout
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .opacity(0)
                    }
                    .disabled(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                
                // Extra spacing below header
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 12)
            }
            
            // Category tabs - SUPER compacto
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categoriesWithCount, id: \.0) { category, count in
                        CategoryTab(
                            category: category,
                            count: count,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4) // MÍNIMO padding
            }
            .background(Color(.systemGray6))
            .padding(.top, showHeader ? 0 : 12) // Padding superior solo sin header
            
            // Content grid
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedByCategory, id: \.key) { categoryGroup in
                        if !categoryGroup.value.isEmpty {
                            CategorySection(
                                category: categoryGroup.key,
                                items: categoryGroup.value,
                                subscriptionManager: subscriptionManager,
                                onItemTap: { item in
                                    selectedItem = item
                                },
                                onPaywallTrigger: {
                                    // Cerrar el detalle y mostrar paywall
                                    selectedItem = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        paywallManager.shouldShowPaywall = true
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGray6))
        }
        .background(Color(.systemGray6))
        .if(showHeader) { view in
            view.ignoresSafeArea(.all)
        }
        .navigationBarHidden(showHeader)
        .fullScreenCover(item: $selectedItem) { item in
            PrintableDetailView(
                item: item,
                onPaywallTrigger: {
                    // Cerrar el detalle y mostrar paywall
                    selectedItem = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        paywallManager.shouldShowPaywall = true
                    }
                }
            )
            .environmentObject(subscriptionManager)
        }
    }
    
    private var groupedByCategory: [(key: PrintableCategory, value: [PrintableItem])] {
        if selectedCategory == .all {
            return Dictionary(grouping: filteredItems) { $0.category }
                .sorted { $0.key.sortOrder < $1.key.sortOrder }
        } else {
            return [(selectedCategory, filteredItems)]
        }
    }
}

// Extension helper para aplicar modificadores condicionalmente
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct CategoryTab: View {
    let category: PrintableCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray4))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategorySection: View {
    let category: PrintableCategory
    let items: [PrintableItem]
    let subscriptionManager: SubscriptionManager
    let onItemTap: (PrintableItem) -> Void
    let onPaywallTrigger: () -> Void
    @State private var showingCategoryDetail = false
    
    // Ordenar items por nombre (alfabéticamente)
    private var sortedItems: [PrintableItem] {
        return items.sorted { $0.title < $1.title }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(String(localized: "See all (\(items.count))")) {
                    showingCategoryDetail = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                // Mostrar solo los primeros 3 items ordenados
                ForEach(sortedItems.prefix(3)) { item in
                    PrintableItemCard(
                        item: item,
                        subscriptionManager: subscriptionManager,
                        onTap: onItemTap
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showingCategoryDetail) {
            // Pasar los items ordenados a la vista de categoría
            PrintableCategoryView(
                category: category, 
                items: sortedItems,
                onPaywallTrigger: onPaywallTrigger
            )
            .environmentObject(subscriptionManager)
        }
    }
}

struct PrintableItemCard: View {
    let item: PrintableItem
    let subscriptionManager: SubscriptionManager
    let onTap: (PrintableItem) -> Void
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .aspectRatio(0.75, contentMode: .fit)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .overlay(
                        Group {
                            if let thumbnail = thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .interpolation(.high) // Interpolación de alta calidad
                                    .aspectRatio(contentMode: .fill)
                                    .clipped()
                            } else {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // SIN crown badge - todos pueden ver el detalle
            }
            
            Text(item.title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .onAppear {
            generateThumbnail()
        }
        .onTapGesture {
            // TODOS pueden ver el detalle
            onTap(item)
        }
    }
    
    private func generateThumbnail() {
        guard thumbnail == nil else { return }
        
        let fileName = item.pdfFileName.replacingOccurrences(of: ".pdf", with: "")
        let categoryPath = "\(item.category.folderName)/\(fileName)"
        
        if let pdfURL = Bundle.main.url(forResource: categoryPath, withExtension: "pdf") {
            generateThumbnailFromURL(pdfURL)
        } else if let originalURL = item.thumbnailURL, FileManager.default.fileExists(atPath: originalURL.path) {
            generateThumbnailFromURL(originalURL)
        } else if let pdfURL = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
            generateThumbnailFromURL(pdfURL)
        }
    }
    
    private func generateThumbnailFromURL(_ pdfURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let pdfDocument = PDFDocument(url: pdfURL),
               let firstPage = pdfDocument.page(at: 0) {
                
                // Generar thumbnail de alta resolución
                let pageRect = firstPage.bounds(for: .mediaBox)
                let scale: CGFloat = 2.5 // Factor de escala para alta resolución
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
                }
            }
        }
    }
}

#Preview {
    PrintablesView()
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}