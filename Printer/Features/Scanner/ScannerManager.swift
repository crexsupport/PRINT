//
//  ScannerManager.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import AVFoundation
import Vision

class ScannerManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isFlashOn = false
    @Published var isDocumentDetected = false
    @Published var documentCorners: [CGPoint] = []
    @Published var capturedImages: [UIImage] = []
    @Published var lastCapturedImage: UIImage?
    @Published var isAutoMode = true
    @Published var autoCaptureCooldown = false
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureCompletionHandler: ((UIImage?) -> Void)?
    private let detectionQueue = DispatchQueue(label: "com.ScannerManager.detection")
    
    // 1️⃣  PROPIEDADES NUEVAS ------------------------------------------
    private var lastDetection = Date(timeIntervalSince1970: 0)   // throttle
    private let detectionInterval: TimeInterval = 0.33           // 3 fps aprox.
    private var detectionTimer: Timer?

    // Simple timers instead of complex threading
    private var autoCaptureTimer: Timer?
    
    var capturedCount: Int {
        return capturedImages.count
    }
    
    private var stableCounter   = 0          // frames "estables"
    private let stableThreshold = 4          // cuántos frames antes de disparar
    private var lastCorners: [CGPoint]?      // para animación
    private var lastObservation: VNRectangleObservation?
    private var filteredCorners: [CGPoint]?     // low-pass result

    override init() {
        super.init()
        // Only check current status without requesting
        checkCurrentCameraStatus()
    }
    
    deinit {
        // Ensure the session is stopped safely.
        // The stop() method should have been called from the view's onDisappear.
        // This is a fallback.
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
        detectionTimer?.invalidate()
        autoCaptureTimer?.invalidate()
    }
    
    // This should be called from the view's onDisappear.
    func stop() {
        detectionTimer?.invalidate()
        detectionTimer = nil
        autoCaptureTimer?.invalidate()
        autoCaptureTimer = nil
        
        // Stop the session on a background thread to avoid blocking the main thread.
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.stopRunning()
            }
        }
    }
    
    private func checkCurrentCameraStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            // Don't setup camera automatically, wait for explicit request
        case .notDetermined, .denied, .restricted:
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
        }
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            setupCamera()
        case .notDetermined:
            requestCameraPermission()
        default:
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
        }
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.setupCamera()
                }
            }
        }
    }
    
    private func setupCamera() {
        // DEFINITIVE FIX: Everything on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            guard self.captureSession == nil else { return }
            
            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .photo
            
            do {
                // Add video input
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    print("No camera available")
                    return
                }
                
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
                
                // Add photo output
                let photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                    self.photoOutput = photoOutput
                }
                
                // Add video output for frame detection
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: self.detectionQueue)
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.videoSettings =
                  [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                    self.videoOutput = videoOutput
                }
                
                session.commitConfiguration()
                self.captureSession = session
                
                // START RUNNING ON BACKGROUND THREAD - DEFINITIVE FIX
                session.startRunning()
                
            } catch {
                print("Camera setup failed: \(error)")
            }
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func setScanMode(manual: Bool) {
        isAutoMode = !manual
        
        if manual {
            // Stop detection in manual mode
            detectionTimer?.invalidate()
            autoCaptureTimer?.invalidate()
            isDocumentDetected = false
            documentCorners = []
            autoCaptureCooldown = false
        } else {
            // Restart detection in auto mode
        }
    }
    
    func captureDocument(completion: @escaping (UIImage?) -> Void) {
        guard let photoOutput = photoOutput,
              captureSession?.isRunning == true else {   // <- guard
            completion(nil)
            return
        }
        
        captureCompletionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func triggerAutoCapture() {
        guard isAutoMode, !autoCaptureCooldown else { return }
        
        autoCaptureCooldown = true
        
        autoCaptureTimer?.invalidate()
        autoCaptureTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.captureDocument { _ in
                // Reset cooldown after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.autoCaptureCooldown = false
                }
            }
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        if videoPreviewLayer == nil {
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
        }
        
        return videoPreviewLayer
    }
    
    func addCapturedImage(_ image: UIImage) {
        capturedImages.append(image)
        lastCapturedImage = image
    }
    
    func clearCapturedImages() {
        capturedImages.removeAll()
        lastCapturedImage = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension ScannerManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.captureCompletionHandler?(nil)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.addCapturedImage(image)
            self.captureCompletionHandler?(image)
        }
    }
}

// 2️⃣  CAPTURA DE FRAMES  ------------------------------------------
extension ScannerManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let buf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Vision request
        let req = VNDetectRectanglesRequest { [weak self] req, _ in
            guard let self,
                  let rect = (req.results as? [VNRectangleObservation])?.first
            else {
                DispatchQueue.main.async { self?.resetDetection() }
                return
            }

            // Filtros básicos
            guard rect.confidence > 0.8,
                  rect.boundingBox.width  > 0.3,
                  rect.boundingBox.height > 0.3 else {
                DispatchQueue.main.async { self.resetDetection() }
                return
            }

            // Normalizar a 0‥1 (y invertido)
            let norm = [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]
              .map { CGPoint(x: CGFloat($0.x), y: CGFloat(1-$0.y)) }

            DispatchQueue.main.async {
                // convert to absolute corner list (0-1 already inverted ↑)
                let newCorners = norm

                // ---- LOW-PASS FILTER (λ = 0.25) ----
                if let prev = self.filteredCorners, prev.count == 4 {
                    self.filteredCorners = zip(prev, newCorners)
                        .map { $0.lerp(to: $1, alpha: 0.25) }
                } else {
                    self.filteredCorners = newCorners
                }

                self.isDocumentDetected = true
                self.documentCorners    = self.filteredCorners ?? newCorners
                self.lastObservation    = rect

                // Stability check (on filtered points)
                if let prev = self.lastCorners,
                   zip(self.documentCorners, prev).allSatisfy({ $0.distance(to: $1) < 0.004 }) {
                    self.stableCounter += 1
                } else {
                    self.stableCounter  = 0
                }
                self.lastCorners = self.documentCorners

                if self.isAutoMode,
                   !self.autoCaptureCooldown,
                   self.stableCounter >= self.stableThreshold {
                    self.triggerAutoCapture()
                }
            }
        }
        req.maximumObservations = 1
        req.minimumConfidence   = 0.8
        try? VNImageRequestHandler(cvPixelBuffer: buf,
                                   orientation: .right,
                                   options: [:]).perform([req])
    }

    private func resetDetection() {
        isDocumentDetected  = false
        documentCorners     = []
        stableCounter       = 0
        lastCorners         = nil
    }
}

// 👉 UTILIDAD: distancia euclídea entre dos CGPoint
// private extension CGPoint {
//     func distance(to other: CGPoint) -> CGFloat {
//         hypot(x - other.x, y - other.y)
//     }
// }
