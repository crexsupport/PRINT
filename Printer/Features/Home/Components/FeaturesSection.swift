//
//  FeaturesSection.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct FeaturesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header con título e indicador integrado
            HStack {
                Text(String(localized: "Features"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Indicador innovador que coincide con el diseño de la app
                InnovativePageIndicator()
            }
            .padding(.horizontal)
            
            MainFeaturesGridView()
        }
    }
}

// Indicador innovador y moderno
struct InnovativePageIndicator: View {
    @State private var currentPage = 0
    
    private let features = PrinterFeature.mainFeatures
    private let featuresPerPage = 4
    
    private var numberOfPages: Int {
        Int(ceil(Double(features.count) / Double(featuresPerPage)))
    }
    
    var body: some View {
        if numberOfPages > 1 {
            HStack(spacing: 4) {
                // Contador visual moderno
                Text("\(currentPage + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 16, height: 16)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.1))
                    )
                    .scaleEffect(1.1)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                
                Text(String(localized: "of"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(numberOfPages)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                // Barra de progreso moderna
                ZStack(alignment: .leading) {
                    // Fondo de la barra
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 24, height: 3)
                    
                    // Progreso activo
                    Capsule()
                        .fill(Color.primary)
                        .frame(
                            width: 24 * CGFloat(currentPage + 1) / CGFloat(numberOfPages),
                            height: 3
                        )
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MainFeaturesPageChanged"))) { notification in
                if let page = notification.object as? Int {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage = page
                    }
                }
            }
        }
    }
}

#Preview {
    FeaturesSection()
        .environmentObject(ScannerManager())
}