//
//  SmoothDocumentShape.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct SmoothDocumentShape: Shape {
    let corners: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        guard corners.count == 4 else { return Path() }
        
        var path = Path()
        
        // Start at first corner
        path.move(to: corners[0])
        
        // Draw lines to each corner with slight smoothing
        for i in 1..<corners.count {
            let currentPoint = corners[i]
            let previousPoint = corners[i - 1]
            
            // Add a slight curve for smoother appearance
            let controlPoint1 = CGPoint(
                x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.1,
                y: previousPoint.y + (currentPoint.y - previousPoint.y) * 0.1
            )
            let controlPoint2 = CGPoint(
                x: currentPoint.x - (currentPoint.x - previousPoint.x) * 0.1,
                y: currentPoint.y - (currentPoint.y - previousPoint.y) * 0.1
            )
            
            path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
        }
        
        // Close the path back to first corner
        let firstPoint = corners[0]
        let lastPoint = corners.last!
        
        let controlPoint1 = CGPoint(
            x: lastPoint.x + (firstPoint.x - lastPoint.x) * 0.1,
            y: lastPoint.y + (firstPoint.y - lastPoint.y) * 0.1
        )
        let controlPoint2 = CGPoint(
            x: firstPoint.x - (firstPoint.x - lastPoint.x) * 0.1,
            y: firstPoint.y - (firstPoint.y - lastPoint.y) * 0.1
        )
        
        path.addCurve(to: firstPoint, control1: controlPoint1, control2: controlPoint2)
        
        return path
    }
}

#Preview {
    SmoothDocumentShape(corners: [
        CGPoint(x: 50, y: 50),
        CGPoint(x: 250, y: 60),
        CGPoint(x: 240, y: 300),
        CGPoint(x: 60, y: 290)
    ])
    .stroke(Color.blue, lineWidth: 3)
    .fill(Color.blue.opacity(0.2))
    .frame(width: 300, height: 350)
}
