//
//  LabelCard.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct LabelCard: View {
    let template: LabelTemplate
    @State private var showLabelCreation = false
    
    var body: some View {
        Button(action: {
            showLabelCreation = true
        }) {
            VStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                
                Text(template.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showLabelCreation) {
            LabelCreationView()
        }
    }
}

#Preview {
    LabelCard(template: LabelTemplate.allTemplates[0])
}