//
//  LabelPrintingView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct LabelPrintingView: View {
    private let labelTemplates = LabelTemplate.allTemplates
    private let labelOptions = LabelOption.allOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Label Printing")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 15) {
                ForEach(labelTemplates) { template in
                    LabelCard(template: template)
                }
            }
            .padding(.horizontal)
            
            // Additional label options
            VStack(spacing: 15) {
                ForEach(labelOptions) { option in
                    LabelOptionCard(option: option)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    LabelPrintingView()
}