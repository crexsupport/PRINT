//
//  LabelCreationView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct LabelCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var paywallManager: PaywallManager
    @State private var selectedFormat: LabelFormat?
    @State private var showImageSelection = false
    
    let showHeader: Bool
    
    init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
    
    private let formats = LabelFormat.allFormats
    
    var body: some View {
        VStack(spacing: 0) {
            // Header condicional
            if showHeader {
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
                    
                    Text("Labels")
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
            }
            
            // Content
            VStack(spacing: 0) {
                // Format selection grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(formats) { format in
                            LabelFormatCard(
                                format: format,
                                isSelected: selectedFormat?.id == format.id,
                                onTap: { selectedFormat = format }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, showHeader ? 20 : 20)
                    .padding(.bottom, 120) // Space for button
                }
                
                Spacer()
                
                // Next button
                if selectedFormat != nil {
                    Button(action: {
                        showImageSelection = true
                    }) {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
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
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: selectedFormat != nil)
                }
            }
        }
        .background(Color(.systemGray6))
        .if(showHeader) { view in
            view.ignoresSafeArea(.all)
        }
        .navigationBarHidden(showHeader)
        .fullScreenCover(isPresented: $showImageSelection) {
            if let format = selectedFormat {
                LabelImageSelectionView(
                    format: format,
                    onPaywallTrigger: {
                        // Cerrar la selección de imagen y mostrar paywall
                        showImageSelection = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            paywallManager.shouldShowPaywall = true
                        }
                    }
                )
            }
        }
    }
}

struct LabelFormatCard: View {
    let format: LabelFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Label preview
                LabelFormatPreview(format: format)
                
                // Format info
                VStack(spacing: 4) {
                    Text(format.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Siempre mostrar las dimensiones
                    Text(format.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct LabelFormatPreview: View {
    let format: LabelFormat
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<format.gridRows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<format.gridColumns, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray4))
                            .aspectRatio(1.4, contentMode: .fit)
                    }
                }
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LabelCreationView()
}