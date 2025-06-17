//
//  MainFeaturesGridView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct MainFeaturesGridView: View {
    private let features = PrinterFeature.mainFeatures
    private let featuresPerPage = 4
    
    // Calculamos cuántas páginas necesitamos
    private var numberOfPages: Int {
        Int(ceil(Double(features.count) / Double(featuresPerPage)))
    }
    
    // Dividimos las features en páginas de 4
    private var featuresPages: [[PrinterFeature]] {
        var pages: [[PrinterFeature]] = []
        
        for pageIndex in 0..<numberOfPages {
            let startIndex = pageIndex * featuresPerPage
            let endIndex = min(startIndex + featuresPerPage, features.count)
            let pageFeatures = Array(features[startIndex..<endIndex])
            pages.append(pageFeatures)
        }
        
        return pages
    }
    
    @State private var currentPage = 0
    
    var body: some View {
        // TabView para scroll horizontal con páginas - SIN indicador propio
        TabView(selection: $currentPage) {
            ForEach(0..<numberOfPages, id: \.self) { pageIndex in
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 12) {
                    ForEach(0..<featuresPerPage, id: \.self) { index in
                        if index < featuresPages[pageIndex].count {
                            FeatureCard(feature: featuresPages[pageIndex][index])
                                .frame(maxWidth: .infinity)
                                // Sombras sutiles
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                        } else {
                            Color.clear
                                .frame(height: 120)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .tag(pageIndex)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 250)
        .onChange(of: currentPage) { _, newPage in
            // Notificar cambio de página al indicador externo
            NotificationCenter.default.post(
                name: NSNotification.Name("MainFeaturesPageChanged"),
                object: newPage
            )
        }
    }
}

// Preview necesitará un ScannerManager también
#Preview {
    MainFeaturesGridView()
        .environmentObject(ScannerManager())
        .padding()
}
