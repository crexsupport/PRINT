import SwiftUI
import Photos
import PhotosUI

enum PhotoPrintStep {
    case permissionRequest
    case photoSelection
    case photoPreview
}

struct PhotoItem: Identifiable, Hashable {
    let id = UUID()
    let asset: PHAsset
    var image: UIImage?
    var isSelected: Bool = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// AÑADIDO: Estructura para vincular PhotoItem con UIImage
struct SelectedPhotoData: Identifiable {
    let id: UUID
    let photoItem: PhotoItem
    let image: UIImage
    
    init(photoItem: PhotoItem, image: UIImage) {
        self.id = photoItem.id
        self.photoItem = photoItem
        self.image = image
    }
}

class PhotoPrintViewModel: ObservableObject {
    @Published var currentStep: PhotoPrintStep = .permissionRequest
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var allPhotos: [PhotoItem] = []
    @Published var selectedPhotos: [UIImage] = []
    @Published var showingImagePicker = false
    @Published var isLoadingPhotos = false
    @Published var isLoading = false
    @Published var selectedPhotoForPreview: PhotoItem?
    
    // AÑADIDO: Array para mantener la relación entre PhotoItem e UIImage
    @Published var selectedPhotoData: [SelectedPhotoData] = []
    
    private let imageManager = PHImageManager.default()
    
    init() {
        checkPhotoLibraryPermission()
    }
    
    func checkPhotoLibraryPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch authorizationStatus {
        case .authorized, .limited:
            // Permission already granted, go directly to photo selection
            currentStep = .photoSelection
            loadPhotos()
        case .denied, .restricted:
            // Permission denied, show settings redirect
            currentStep = .permissionRequest
        case .notDetermined:
            // Permission not asked yet, show permission request
            requestPhotoPermission()
            currentStep = .permissionRequest
        @unknown default:
            currentStep = .permissionRequest
        }
    }
    
    func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                switch status {
                case .authorized, .limited:
                    self?.currentStep = .photoSelection
                    self?.loadPhotos()
                case .denied, .restricted:
                    // Handle denied permission - could show settings redirect
                    print("Photo library access denied")
                case .notDetermined:
                    // This shouldn't happen after requesting permission
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    func handlePermissionDenied() {
        // Open Settings app to let user manually enable permission
        openSettings()
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func loadPhotos() {
        isLoadingPhotos = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1000 // Limit for performance
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var photoItems: [PhotoItem] = []
            
            assets.enumerateObjects { asset, _, _ in
                photoItems.append(PhotoItem(asset: asset))
            }
            
            DispatchQueue.main.async {
                self?.allPhotos = photoItems
                self?.isLoadingPhotos = false
            }
        }
    }
    
    func togglePhotoSelection(_ photo: PhotoItem) {
        // Find the index in allPhotos and update it
        if let index = allPhotos.firstIndex(where: { $0.id == photo.id }) {
            allPhotos[index].isSelected.toggle()
            
            if allPhotos[index].isSelected {
                // Load image for selected photo
                loadImage(for: allPhotos[index]) { image in
                    if let image = image {
                        // CORREGIDO: Agregar a ambos arrays manteniendo la relación
                        let photoData = SelectedPhotoData(photoItem: photo, image: image)
                        self.selectedPhotoData.append(photoData)
                        self.selectedPhotos.append(image)
                    }
                }
            } else {
                // CORREGIDO: Eliminar específicamente la foto correcta
                if let dataIndex = self.selectedPhotoData.firstIndex(where: { $0.id == photo.id }) {
                    self.selectedPhotoData.remove(at: dataIndex)
                }
                
                // Reconstruir selectedPhotos desde selectedPhotoData para mantener sincronización
                self.selectedPhotos = self.selectedPhotoData.map { $0.image }
            }
        }
        
        // Update the preview photo if it's the same one
        if let previewPhoto = selectedPhotoForPreview, previewPhoto.id == photo.id {
            if let updatedPhoto = allPhotos.first(where: { $0.id == photo.id }) {
                selectedPhotoForPreview = updatedPhoto
            }
        }
    }
    
    func selectPhotoForPreview(_ photo: PhotoItem) {
        // Find the current state of this photo
        if let currentPhoto = allPhotos.first(where: { $0.id == photo.id }) {
            selectedPhotoForPreview = currentPhoto
        } else {
            selectedPhotoForPreview = photo
        }
    }
    
    func goToPreviousStep() {
        switch currentStep {
        case .photoPreview:
            if selectedPhotoForPreview != nil {
                selectedPhotoForPreview = nil
            } else {
                currentStep = .photoSelection
            }
        case .photoSelection:
            currentStep = .permissionRequest
        case .permissionRequest:
            break
        }
    }
    
    func loadImage(for photoItem: PhotoItem, targetSize: CGSize = CGSize(width: 300, height: 300), completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: photoItem.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    func addPhoto(_ image: UIImage) {
        selectedPhotos.append(image)
    }
    
    func removePhoto(at index: Int) {
        guard index < selectedPhotos.count else { return }
        selectedPhotos.remove(at: index)
    }
    
    func removeAllPhotos() {
        selectedPhotos.removeAll()
        selectedPhotoData.removeAll()
        
        // AÑADIDO: Deseleccionar todas las fotos en allPhotos
        for i in allPhotos.indices {
            allPhotos[i].isSelected = false
        }
    }
    
    func printPhotos() {
        // CORREGIDO: Usar las imágenes de selectedPhotoData que están correctamente sincronizadas
        let imagesToPrint = selectedPhotoData.map { $0.image }
        
        guard !imagesToPrint.isEmpty else { return }
        
        print("DEBUG: Printing \(imagesToPrint.count) photos")
        print("DEBUG: Selected photos in allPhotos: \(allPhotos.filter { $0.isSelected }.count)")
        
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .photo
        printInfo.jobName = "Photos"
        
        printController.printInfo = printInfo
        printController.printingItems = imagesToPrint
        
        printController.present(animated: true) { (controller, completed, error) in
            if let error = error {
                print("Print error: \(error.localizedDescription)")
            } else if completed {
                print("Photos printed successfully")
            }
        }
    }
}
