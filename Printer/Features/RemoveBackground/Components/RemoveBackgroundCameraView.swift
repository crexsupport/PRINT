import SwiftUI
import AVFoundation

struct RemoveBackgroundCameraView: View {
    @ObservedObject var viewModel: RemoveBackgroundViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraController = CameraController()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: cameraController.session)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Take Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Button {
                        cameraController.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Instructions
                VStack(spacing: 12) {
                    Text("🎯 Position your subject clearly")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Text("For best results, ensure good lighting and contrast")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                
                // Capture button
                Button {
                    cameraController.capturePhoto { image in
                        if let image = image {
                            viewModel.processSelectedImage(image)
                            dismiss()
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .stroke(Color.black.opacity(0.2), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .scaleEffect(cameraController.isCapturing ? 0.8 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: cameraController.isCapturing)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            cameraController.startSession()
        }
        .onDisappear {
            cameraController.stopSession()
        }
    }
}

// MARK: - Camera Controller
class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var videoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    @Published var isCapturing = false
    
    private var photoCompletionHandler: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func flipCamera() {
        guard let currentInput = currentInput else { return }
        
        session.removeInput(currentInput)
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            session.addInput(currentInput)
            return
        }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            self.currentInput = newInput
        } else {
            session.addInput(currentInput)
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        isCapturing = true
        photoCompletionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        videoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            DispatchQueue.main.async {
                self.isCapturing = false
            }
        }
        
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCompletionHandler?(nil)
            return
        }
        
        photoCompletionHandler?(image)
    }
}

#Preview {
    RemoveBackgroundCameraView(viewModel: RemoveBackgroundViewModel())
}