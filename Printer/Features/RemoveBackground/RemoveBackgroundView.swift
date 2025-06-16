import SwiftUI
import PhotosUI
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Data Models
struct BackgroundRemovedImage: Identifiable {
    let id = UUID()
    let originalImage: UIImage
    let processedImage: UIImage
    let processingDate: Date
    
    init(original: UIImage, processed: UIImage) {
        self.originalImage = original
        self.processedImage = processed
        self.processingDate = Date()
    }
}

// MARK: - Background Removal Service
class BackgroundRemovalService: ObservableObject {
    
    static func removeBackground(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            print("Starting background removal process...")
            
            // Try the simple approach first - works on all iOS versions
            if let result = self.createSimpleBackgroundRemoval(image: image) {
                print("Simple background removal succeeded")
                DispatchQueue.main.async {
                    completion(result)
                }
                return
            }
            
            // Try person segmentation for iOS 15+
            if #available(iOS 15.0, *) {
                if let result = self.removeBackgroundWithPersonSegmentation(image: image) {
                    print("Person segmentation succeeded")
                    DispatchQueue.main.async {
                        completion(result)
                    }
                    return
                }
            }
            
            print("All background removal methods failed")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    private static func createSimpleBackgroundRemoval(image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage from UIImage")
            return nil
        }
        
        let context = CIContext()
        
        // Create a simple mask using color-based segmentation
        // This approach creates a basic cutout effect
        
        // Convert to grayscale first
        let grayscaleFilter = CIFilter.colorMonochrome()
        grayscaleFilter.inputImage = inputImage
        grayscaleFilter.color = CIColor.white
        grayscaleFilter.intensity = 1.0
        
        guard let grayscaleImage = grayscaleFilter.outputImage else {
            print("Failed to create grayscale image")
            return nil
        }
        
        // Apply edge detection
        let edgeFilter = CIFilter.edgeWork()
        edgeFilter.inputImage = grayscaleImage
        edgeFilter.radius = 2.0
        
        guard let edgeImage = edgeFilter.outputImage else {
            print("Failed to create edge image")
            return nil
        }
        
        // Create a mask by inverting edges
        let invertFilter = CIFilter.colorInvert()
        invertFilter.inputImage = edgeImage
        
        guard let maskImage = invertFilter.outputImage else {
            print("Failed to create mask")
            return nil
        }
        
        // Apply some blur to soften edges
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = maskImage
        blurFilter.radius = 3.0
        
        guard let blurredMask = blurFilter.outputImage else {
            print("Failed to blur mask")
            return nil
        }
        
        // Apply the mask to create transparency
        let compositeFilter = CIFilter.blendWithMask()
        compositeFilter.inputImage = inputImage
        compositeFilter.maskImage = blurredMask
        compositeFilter.backgroundImage = CIImage.clear
        
        guard let outputImage = compositeFilter.outputImage?.cropped(to: inputImage.extent) else {
            print("Failed to apply mask")
            return nil
        }
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(outputImage.cropped(to: inputImage.extent), from: inputImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }
        
        let resultImage = UIImage(cgImage: cgImage)
        print("Simple background removal completed successfully")
        return resultImage
    }
    
    @available(iOS 15.0, *)
    private static func removeBackgroundWithPersonSegmentation(image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else { return nil }
        
        print("Attempting person segmentation...")
        
        var resultImage: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        
        let request = VNGeneratePersonSegmentationRequest { request, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("Person segmentation error: \(error)")
                return
            }
            
            guard let result = request.results?.first as? VNPixelBufferObservation else {
                print("No person segmentation results found")
                return
            }
            
            print("Person segmentation completed, applying mask...")
            
            let maskImage = CIImage(cvPixelBuffer: result.pixelBuffer)
            
            let filtered = applyPersonMask(maskImage, to: inputImage)
            
            let context = CIContext()
            guard let cgImage = context.createCGImage(filtered, from: inputImage.extent) else {
                print("Failed to create final CGImage")
                return
            }
            
            resultImage = UIImage(cgImage: cgImage)
            print("Person segmentation mask applied successfully")
        }
        
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        do {
            try handler.perform([request])
            print("Vision request performed")
        } catch {
            print("Vision request failed: \(error)")
        }
        
        semaphore.wait()
        return resultImage
    }
    
    private static func applyPersonMask(_ mask: CIImage, to image: CIImage) -> CIImage {
        // NO invertir la máscara de Vision, ya debería tener el primer plano como blanco/alto valor.
        // Solo asegurar el mismo extent.
        let croppedMask = mask.cropped(to: image.extent)

        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = croppedMask // Usar la máscara original (recortada)
        filter.backgroundImage = CIImage.clear
        
        // Recortar la salida final también, por si acaso.
        return (filter.outputImage ?? image)
            .cropped(to: image.extent)
    }
    
    private static func applyInstanceMask(_ mask: CIImage, to image: CIImage) -> CIImage {
        // NO invertir la máscara de Vision.
        let croppedMask = mask.cropped(to: image.extent)

        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = croppedMask // Usar la máscara original (recortada)
        filter.backgroundImage = CIImage.clear

        // Recortar la salida final.
        return (filter.outputImage ?? image)
            .cropped(to: image.extent)
    }
}

// MARK: - ViewModel
class RemoveBackgroundViewModel: ObservableObject {
    @Published var currentStep: RemoveBackgroundStep = .selection
    @Published var selectedImageSource: ImageSource?
    @Published var originalImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var addShadow = true
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    private var progressTimer: Timer?
    
    enum ImageSource {
        case gallery
        case camera
    }
    
    func selectImageSource(_ source: ImageSource) {
        selectedImageSource = source
        switch source {
        case .gallery:
            showingImagePicker = true
        case .camera:
            showingCamera = true
        }
    }
    
    func handleSelectedPhotoItem(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        showingImagePicker = false
        selectedImageSource = nil
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        print("Image loaded successfully, starting processing...")
                        self.processSelectedImage(image)
                    } else {
                        self.errorMessage = "Failed to load image data"
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load image: \(error.localizedDescription)"
                }
                // Reset the selected item
                self.selectedPhotoItem = nil
            }
        }
    }
    
    func processSelectedImage(_ image: UIImage) {
        print("Processing image with size: \(image.size)")
        
        originalImage = image
        currentStep = .processing
        isProcessing = true
        processingProgress = 0.0
        
        // Clear any previous state
        selectedImageSource = nil
        showingImagePicker = false
        showingCamera = false
        
        // Simulate processing progress
        startProgressAnimation()
        
        BackgroundRemovalService.removeBackground(from: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopProgressAnimation()
                self?.isProcessing = false
                
                if let processedImage = result {
                    print("Background removal successful!")
                    self?.processedImage = processedImage
                    self?.currentStep = .result
                } else {
                    print("Background removal failed")
                    self?.errorMessage = "Unable to process this image. Try using a photo with clear subjects and good contrast against the background."
                    self?.currentStep = .selection
                }
            }
        }
    }
    
    private func startProgressAnimation() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.processingProgress < 0.9 {
                self.processingProgress += 0.03
            }
        }
    }
    
    private func stopProgressAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil
        processingProgress = 1.0
    }
    
    func resetToSelection() {
        currentStep = .selection
        selectedImageSource = nil
        originalImage = nil
        processedImage = nil
        isProcessing = false
        processingProgress = 0.0
        errorMessage = nil
        addShadow = true
        selectedPhotoItem = nil
        showingImagePicker = false
        showingCamera = false
    }
    
    func returnToPreviousStep() {
        switch currentStep {
        case .processing:
            currentStep = .selection
        case .result:
            currentStep = .selection
        case .selection:
            break
        }
    }
    
    func getFinalImage() -> UIImage? {
        guard let processed = processedImage else { return nil }
        
        if addShadow {
            return addDropShadow(to: processed)
        } else {
            return processed
        }
    }
    
    private func addDropShadow(to image: UIImage) -> UIImage? {
        let shadowOffset = CGSize(width: 0, height: 10)
        let shadowBlur: CGFloat = 20
        let shadowColor = UIColor.black.withAlphaComponent(0.3)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(
            width: image.size.width + shadowBlur * 2,
            height: image.size.height + shadowBlur * 2 + shadowOffset.height
        ))
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Draw shadow
            cgContext.setShadow(
                offset: shadowOffset,
                blur: shadowBlur,
                color: shadowColor.cgColor
            )
            
            // Draw image
            let imageRect = CGRect(
                x: shadowBlur,
                y: shadowBlur,
                width: image.size.width,
                height: image.size.height
            )
            image.draw(in: imageRect)
        }
    }
}

// MARK: - Step Enum
enum RemoveBackgroundStep {
    case selection
    case processing
    case result
}

// MARK: - Main RemoveBackgroundView
struct RemoveBackgroundView: View {
    @StateObject private var viewModel = RemoveBackgroundViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.currentStep {
                case .selection:
                    RemoveBackgroundSelectionView(viewModel: viewModel)
                case .processing:
                    RemoveBackgroundProcessingView(viewModel: viewModel)
                case .result:
                    RemoveBackgroundResultView(viewModel: viewModel)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep == .selection {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    } else {
                        Button {
                            viewModel.returnToPreviousStep()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .result, let finalImage = viewModel.getFinalImage() {
                        ShareLink(item: Image(uiImage: finalImage), preview: SharePreview("Background Removed", image: Image(uiImage: finalImage))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .photosPicker(
            isPresented: $viewModel.showingImagePicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
            viewModel.handleSelectedPhotoItem(newItem)
        }
        .fullScreenCover(isPresented: $viewModel.showingCamera) {
            RemoveBackgroundCameraView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .selection:
            return "Remove Background"
        case .processing:
            return "Processing..."
        case .result:
            return "Background Removed"
        }
    }
}

#Preview {
    RemoveBackgroundView()
}
