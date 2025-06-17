//
//  DocumentOverlayView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct DocumentOverlayView: View {
    let corners: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            if corners.count == 4 {
                SmoothDocumentShape(corners: corners.map { corner in
                    CGPoint(
                        x: corner.x * geometry.size.width,
                        y: corner.y * geometry.size.height
                    )
                })
                .stroke(Color.blue, lineWidth: 3)
                .fill(Color.blue.opacity(0.1))
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    DocumentOverlayView(corners: [
        CGPoint(x: 0.2, y: 0.2),
        CGPoint(x: 0.8, y: 0.2),
        CGPoint(x: 0.8, y: 0.8),
        CGPoint(x: 0.2, y: 0.8)
    ])
    .frame(width: 300, height: 400)
    .background(Color.black)
}
