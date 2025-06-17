//
//  LabelCard.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct LabelCard: View {
    let template: LabelTemplate
    
    var body: some View {
        Button(action: {
            // Label action
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
    }
}

#Preview {
    LabelCard(template: LabelTemplate.allTemplates[0])
}
