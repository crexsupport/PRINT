//
//  FeaturesSection.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct FeaturesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Features")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            MainFeaturesGridView()
        }
    }
}

#Preview {
    FeaturesSection()
        .environmentObject(ScannerManager())
}