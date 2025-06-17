import SwiftUI
import PDFKit // Para la vista previa del PDF

struct TestPrintView: View {
    @ObservedObject var viewModel: PrinterSetupWizardViewModel
    
    // Simular un PDF de prueba
    private var testPDF: PDFDocument? {
        if let url = Bundle.main.url(forResource: "TestPrintPage", withExtension: "pdf") {
            return PDFDocument(url: url)
        }
        // Si no se encuentra, crear un PDF simple programáticamente
        let pdfDocument = PDFDocument()
        let pdfPage = PDFPage()
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        
        let textAnnotation = PDFAnnotation(bounds: bounds.insetBy(dx: 50, dy: 50), forType: .freeText, withProperties: nil)
        textAnnotation.contents = "Print Test\n\nYour document printed successfully. Your printer connection and setting is all set for use."
        textAnnotation.font = UIFont.systemFont(ofSize: 24)
        textAnnotation.alignment = .center
        pdfPage.addAnnotation(textAnnotation)
        pdfDocument.insert(pdfPage, at: 0)
        return pdfDocument
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer(minLength: 20)
            
            Text("Imprimir página de prueba")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            if let pdfDoc = testPDF {
                PDFKitRepresentedView(document: pdfDoc)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                Text("No se pudo cargar la página de prueba.")
                    .foregroundColor(.red)
            }
            
            Text("Documento PDF · 22 KB") // Información simulada
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                // Aquí iría la lógica para imprimir la página de prueba
                print("Imprimiendo página de prueba...")
                // Después de intentar imprimir, mostrar el pop-up de confirmación
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Simular retraso de impresión
                     viewModel.showingTestPrintConfirmation = true
                }
            }) {
                HStack {
                    Image(systemName: "printer.fill")
                    Text("Imprimir página de prueba")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(12)
                .shadow(color: .green.opacity(0.3), radius: 5, y: 3)
            }
            
            Spacer()

            Button(action: {
                // Si el usuario decide saltar la impresión de prueba o ya la hizo
                 viewModel.nextStep()
            }) {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
            }
            .padding(.bottom)
        }
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $viewModel.showingTestPrintConfirmation) {
            TestPrintConfirmationPopup(viewModel: viewModel)
                .presentationDetents([.fraction(0.4), .medium]) // Ajustar altura del sheet
                .presentationDragIndicator(.visible)
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = UIColor.systemGray6
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}


struct TestPrintConfirmationPopup: View {
    @ObservedObject var viewModel: PrinterSetupWizardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("¿Imprimir correctamente?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.top)

            Text("¿Configuraste tu impresora y la imprimió correctamente?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Sí") {
                viewModel.confirmTestPrint(success: true)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .frame(maxWidth: .infinity)


            Button("No") {
                viewModel.confirmTestPrint(success: false) // Podría llevar a una pantalla de ayuda o reintento
                dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            Button("Intentar otra vez") {
                // Aquí se podría re-llamar la lógica de impresión
                dismiss() // Cierra el popup para que el usuario pueda volver a pulsar "Imprimir"
            }
            .foregroundColor(.blue)
            .padding(.bottom)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}


#Preview {
    TestPrintView(viewModel: PrinterSetupWizardViewModel())
}
