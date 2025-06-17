//
//  CameraPreviewView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let scannerManager: ScannerManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        
        DispatchQueue.main.async {
            if let previewLayer = scannerManager.getPreviewLayer() {
                view.setPreviewLayer(previewLayer)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Updates are handled by the scanner manager
    }
}

class CameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer?.removeFromSuperlayer()
        previewLayer = layer
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
    }
}
