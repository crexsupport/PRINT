//
//  DocumentScannerView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import VisionKit // Asegúrate de importar VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No se necesita actualización aquí para este caso de uso simple
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.scannedImages.append(contentsOf: images) // Añade las imágenes escaneadas
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss() // Cierra la vista si el usuario cancela
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document Camera Failed with error: \(error.localizedDescription)")
            // Aquí podrías, por ejemplo, mostrar una alerta al usuario informando del error
            parent.dismiss() // Cierra la vista también en caso de error
        }
    }
}

// Preview (opcional, pero útil para diseño)
// #Preview {
//     StatefulPreviewWrapper([]) { imagesBinding in
//         DocumentScannerView(scannedImages: imagesBinding)
//     }
// }
//
// struct StatefulPreviewWrapper<Value, Content: View>: View {
//     @State var value: Value
//     var content: (Binding<Value>) -> Content
//
//     var body: some View {
//         content($value)
//     }
//
//     init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
//         self._value = State(wrappedValue: value)
//         self.content = content
//     }
// }
