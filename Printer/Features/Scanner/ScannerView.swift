//
//  ScannerView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var scannerManager = ScannerManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    @State private var isManualMode = false
    @State private var showingDocumentScanner = false // Para presentar DocumentScannerView
    @State private var showingPreview = false // Se gestionará diferente
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if scannerManager.isAuthorized {
                // Camera view
                CameraPreviewView(scannerManager: scannerManager)
                    .ignoresSafeArea()
                
                // Overlay UI
                VStack {
                    // Top controls
                    HStack {
                        Button(String(localized: "Cancel")) {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 17))
                        
                        Spacer()
                        
                        // Flash toggle
                        Button(action: {
                            scannerManager.toggleFlash()
                        }) {
                            Image(systemName: scannerManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Scan mode toggle
                        Button(isManualMode ? String(localized: "Manual") : String(localized: "Auto")) {
                            isManualMode.toggle()
                            scannerManager.setScanMode(manual: isManualMode)
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 17))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Document detection feedback
                    if scannerManager.isDocumentDetected && !isManualMode {
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 8) {
                                if scannerManager.autoCaptureCooldown {
                                    Text(String(localized: "Capturing in 2 seconds..."))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                } else {
                                    Text(String(localized: "Document detected!"))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(String(localized: "Hold steady for auto capture"))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            )
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // Bottom controls
                    HStack(spacing: 60) {
                        // Gallery button (thumbnail)
                        Button(action: {
                            // Acción para el botón de la miniatura:
                            // Si hay imágenes, mostrar DocumentCollectionView
                            if scannerManager.capturedCount > 0 {
                                // Necesitaremos un nuevo @State para controlar DocumentCollectionView
                                // o reutilizar showingPreview si esa es la intención.
                                // Por ahora, asumamos que queremos mostrarlo desde aquí.
                                // Esta acción ahora se encargará de mostrar el preview.
                                // La variable $showingPreview se usará para DocumentCollectionView.
                                self.showingPreview = true
                            }
                        }) {
                            // ... (código de la miniatura no cambia) ...
                            if let lastImage = scannerManager.lastCapturedImage {
                                Image(uiImage: lastImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "photo.on.rectangle")
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        // Capture button (AHORA PRESENTA DocumentScannerView)
                        Button(action: {
                            // ESTE BOTÓN AHORA INICIA EL ESCANEO
                            self.showingDocumentScanner = true
                        }) {
                            // ... (código del botón de captura grande no cambia) ...
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                            }
                        }
                        
                        // Botón "Save X" (AHORA SOLO REVISA, no activa escáner)
                        Button(action: {
                            if scannerManager.capturedCount > 0 {
                                // Muestra DocumentCollectionView si hay imágenes
                                self.showingPreview = true
                            }
                        }) {
                            Text(scannerManager.capturedCount > 0 ? String(localized: "Review (\(scannerManager.capturedCount))") : String(localized: "Scan"))
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(scannerManager.capturedCount > 0 ? Color.blue : Color.gray.opacity(0.3))
                                )
                        }
                        // Ya no necesita .disabled, su texto y acción cambian.
                    }
                    .padding(.bottom, 40)
                }
                
                if scannerManager.isDocumentDetected {
                    DocumentOverlayView(corners: scannerManager.documentCorners)
                }
                
            } else {
                // Camera permission not granted
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text(String(localized: "Camera Access Required"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(String(localized: "Allow camera access to scan documents and take photos to add to your printables."))
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(String(localized: "Allow Camera Access")) {
                        scannerManager.requestCameraPermission()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                }
            }
        }
        .onAppear {
            scannerManager.checkCameraPermission()
        }
        .onDisappear {
            scannerManager.stop()
        }
        
        // ESTE .sheet AHORA ES PARA DocumentScannerView (el escáner nativo)
        .sheet(isPresented: $showingDocumentScanner) {
            // Pasamos el array donde DocumentScannerView guardará las imágenes
            DocumentScannerView(scannedImages: $scannerManager.capturedImages)
        }
        
        // AÑADIR UN NUEVO .sheet (o reutilizar el anterior si $showingPreview se usa solo para esto)
        // PARA DocumentCollectionView (la vista de revisión de imágenes)
        .sheet(isPresented: $showingPreview) { // Este es el que se activa desde la miniatura o "Review (X)"
            DocumentCollectionView(images: scannerManager.capturedImages) {
                // La acción onSave de DocumentCollectionView (botón "Print(X)")
                // podría hacer algo como:
                // 1. Iniciar el proceso de impresión real.
                // 2. O simplemente cerrar esta vista y volver a ScannerView.
                // Por ahora, solo cerramos para volver a ScannerView.
                self.showingPreview = false // Cierra DocumentCollectionView
                // dismiss() // Esto cerraría ScannerView, quizás no es lo que quieres aquí.
            }
        }
    }
}

#Preview {
    ScannerView()
}