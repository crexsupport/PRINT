//
//  ActivityViewController.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}