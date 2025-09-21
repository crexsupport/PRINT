//
//  PrintableDetailView.swift
//  Printer
//
//  Created by Pol.
//

import SwiftUI
import PDFKit

struct PrintableDetailView: View {
    let item: PrintableItem
    let onPaywallTrigger: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var isBlackAndWhite: Bool = false
    @State private var pdfDocument: PDFDocument?
    @State private var originalPageImage: UIImage? // Imagen original sin filtro
    @State private var displayPageImage: UIImage? // Imagen que se muestra (con o sin filtro)
    @State private var currentPageIndex: Int = 0
    
    var totalPages: Int {
        return pdfDocument?.pageCount ?? 1
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
                
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    handlePrintTap()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(String(localized: "Print"))
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 0.1, green: 0.3, blue: 0.7).opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            
            // Document preview
            ScrollView {
                VStack(spacing: 20) {
                    // Document image (más pequeño)
                    Group {
                        if let image = displayPageImage {
                            VStack(spacing: 12) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 500)
                                    .padding(.horizontal, 24)
                                    .grayscale(isBlackAndWhite ? 1.0 : 0.0) // Añadir filtro SwiftUI como backup
                                
                                // Page navigation si hay múltiples páginas
                                if totalPages > 1 {
                                    HStack(spacing: 16) {
                                        Button(action: {
                                            if currentPageIndex > 0 {
                                                currentPageIndex -= 1
                                                loadCurrentPage()
                                            }
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(currentPageIndex > 0 ? .blue : .gray)
                                        }
                                        .disabled(currentPageIndex == 0)
                                        
                                        Text(String(localized: "\(currentPageIndex + 1) of \(totalPages)"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                        
                                        Button(action: {
                                            if currentPageIndex < totalPages - 1 {
                                                currentPageIndex += 1
                                                loadCurrentPage()
                                            }
                                        }) {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(currentPageIndex < totalPages - 1 ? .blue : .gray)
                                        }
                                        .disabled(currentPageIndex >= totalPages - 1)
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        } else {
                            // Placeholder más pequeño
                            Rectangle()
                                .fill(Color.white)
                                .aspectRatio(0.75, contentMode: .fit)
                                .frame(maxHeight: 500)
                                .overlay(
                                    VStack(spacing: 16) {
                                        Image(systemName: item.category.icon)
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray.opacity(0.3))
                                        
                                        Text(String(localized: "Loading..."))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .padding(.horizontal, 24)
                        }
                    }
                    
                    // Print Settings Card (igual que antes)
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            HStack {
                                Text(String(localized: "Print settings"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                        }
                        
                        // Color mode selector
                        HStack(spacing: 16) {
                            // Color option
                            Button(action: {
                                isBlackAndWhite = false
                                updateDisplayImage()
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(
                                                colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 40, height: 30)
                                        
                                        if !isBlackAndWhite {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                    }
                                    
                                    Text(String(localized: "Color"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(isBlackAndWhite ? .gray : .blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            // Black & White option
                            Button(action: {
                                isBlackAndWhite = true
                                updateDisplayImage()
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(
                                                colors: [.black, .gray, .white],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 40, height: 30)
                                        
                                        if isBlackAndWhite {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                    }
                                    
                                    Text(String(localized: "B&W"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(isBlackAndWhite ? .blue : .gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        // Additional print info
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Text(String(localized: "Tap to preview how your document will print"))
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 32)
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGray6))
        }
        .background(Color(.systemGray6))
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            loadPDFDocument()
        }
    }
    
    private func loadPDFDocument() {
        let fileName = item.pdfFileName.replacingOccurrences(of: ".pdf", with: "")
        let categoryPath = "\(item.category.folderName)/\(fileName)"
        
        if let pdfURL = Bundle.main.url(forResource: categoryPath, withExtension: "pdf") {
            loadRealPDF(from: pdfURL)
        } else if let pdfURL = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
            loadRealPDF(from: pdfURL)
        } else {
            createSampleImage()
        }
    }
    
    private func loadRealPDF(from url: URL) {
        guard let pdfDocument = PDFDocument(url: url) else {
            createSampleImage()
            return
        }
        
        self.pdfDocument = pdfDocument
        self.currentPageIndex = 0
        loadCurrentPage()
    }
    
    private func loadCurrentPage() {
        guard let pdfDocument = pdfDocument,
              let currentPage = pdfDocument.page(at: currentPageIndex) else {
            return
        }
        
        let pageRect = currentPage.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let pageImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(pageRect)
            
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            currentPage.draw(with: .mediaBox, to: context.cgContext)
        }
        
        originalPageImage = pageImage
        updateDisplayImage()
    }
    
    private func updateDisplayImage() {
        // Simplificar: solo usar la imagen original y dejar que SwiftUI maneje el filtro
        displayPageImage = originalPageImage
    }
    
    private func createSampleImage() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 612, height: 792))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 612, height: 792)))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            "*HAPPY*".draw(in: CGRect(x: 50, y: 200, width: 512, height: 40), withAttributes: titleAttributes)
            
            let mainAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 48),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            "Birthday!".draw(in: CGRect(x: 50, y: 260, width: 512, height: 80), withAttributes: mainAttributes)
        }
        
        originalPageImage = image
        updateDisplayImage()
    }
    
    private func handlePrintTap() {
        // Usar callback para triggerear paywall desde el padre
        if subscriptionManager.isSubscribed {
            printDocument()
        } else {
            onPaywallTrigger()
        }
        
        // Código temporal comentado - ya no es necesario
        /*
        // Temporalmente permitir impresión sin suscripción para pruebas
        printDocument()
        */
    }
    
    private func printDocument() {
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = item.title
        
        // Configurar para blanco y negro si está seleccionado
        if isBlackAndWhite {
            printInfo.outputType = .grayscale
        }
        
        printController.printInfo = printInfo
        
        let fileName = item.pdfFileName.replacingOccurrences(of: ".pdf", with: "")
        let categoryPath = "\(item.category.folderName)/\(fileName)"
        
        // Si está en modo blanco y negro, usar la imagen procesada
        if isBlackAndWhite {
            if let originalImage = originalPageImage {
                let blackAndWhiteImage = convertToBlackAndWhite(image: originalImage)
                printController.printingItem = blackAndWhiteImage
            } else if let pdfURL = Bundle.main.url(forResource: categoryPath, withExtension: "pdf") {
                printController.printingItem = pdfURL
            } else if let pdfURL = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
                printController.printingItem = pdfURL
            }
        } else {
            // Modo color normal
            if let pdfURL = Bundle.main.url(forResource: categoryPath, withExtension: "pdf") {
                printController.printingItem = pdfURL
            } else if let pdfURL = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
                printController.printingItem = pdfURL
            } else {
                printController.printingItem = displayPageImage
            }
        }
        
        printController.present(animated: true) { (controller, completed, error) in
            if let error = error {
                print("Print error: \(error.localizedDescription)")
            } else if completed {
                print("\(item.title) printed successfully")
            }
        }
    }
    
    // Función para convertir imagen a blanco y negro
    private func convertToBlackAndWhite(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = cgImage.width
        let height = cgImage.height
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return image }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let grayImage = context.makeImage() else { return image }
        
        return UIImage(cgImage: grayImage)
    }
}