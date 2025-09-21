//
//  LabelOptionCard.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct LabelOptionCard: View {
    let option: LabelOption
    @State private var showLabelCreation = false
    
    var body: some View {
        Button(action: {
            showLabelCreation = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: option.icon)
                    .font(.system(size: 24))
                    .foregroundColor(option.color)
                
                Text(option.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.purple, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showLabelCreation) {
            LabelCreationView()
        }
    }
}

#Preview {
    LabelOptionCard(option: LabelOption.allOptions[0])
}