import SwiftUI
import Combine

enum PrinterSetupWizardStep: Int, CaseIterable {
    case brandSelection = 1
    case wifiCheck = 2
    case testPrint = 3
    case finalConfirmation = 4 // Corresponde a "Configuración de la impresora..."

    var title: String {
        switch self {
        case .brandSelection:
            return "Conecte su impresora a Wi-Fi"
        case .wifiCheck:
            return "Verificar impresora Wi-Fi"
        case .testPrint:
            return "Impresión de prueba"
        case .finalConfirmation:
            return "Configuración de la impresora"
        }
    }
}

class PrinterSetupWizardViewModel: ObservableObject {
    @Published var currentStep: PrinterSetupWizardStep = .brandSelection
    @Published var selectedBrand: PrinterBrand?
    @Published var isPrinterReadySelected: Bool? // true si "La impresora está lista", false si "no está lista"
    @Published var showingTestPrintConfirmation: Bool = false
    @Published var testPrintSuccessful: Bool? // nil = no respondido, true = sí, false = no

    // Para la animación de confetti en la pantalla final
    @Published var showConfetti: Bool = false


    func nextStep() {
        guard let currentIndex = PrinterSetupWizardStep.allCases.firstIndex(of: currentStep) else { return }
        let nextIndex = currentIndex + 1
        if nextIndex < PrinterSetupWizardStep.allCases.count {
            currentStep = PrinterSetupWizardStep.allCases[nextIndex]
            if currentStep == .finalConfirmation {
                // Simular un proceso de configuración
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showConfetti = true
                }
            }
        } else {
            // Flujo completado
        }
    }

    func previousStep() {
        guard let currentIndex = PrinterSetupWizardStep.allCases.firstIndex(of: currentStep) else { return }
        let prevIndex = currentIndex - 1
        if prevIndex >= 0 {
            currentStep = PrinterSetupWizardStep.allCases[prevIndex]
        }
    }
    
    func selectBrand(_ brand: PrinterBrand) {
        selectedBrand = brand
        // Podrías añadir lógica aquí si seleccionar una marca lleva a un paso diferente
        // Por ahora, simplemente avanzamos al siguiente.
        // nextStep() // Lo llamaremos desde el botón "Continuar" o la acción de la vista
    }

    func selectPrinterStatus(isReady: Bool) {
        isPrinterReadySelected = isReady
        // nextStep()
    }
    
    func confirmTestPrint(success: Bool) {
        testPrintSuccessful = success
        showingTestPrintConfirmation = false
        if success {
            nextStep() // Avanzar al paso final si la impresión fue exitosa
        } else {
            // El usuario podría querer "Intentar otra vez" o "Conseguir ayuda"
            // Por ahora, si no es exitosa, se queda en la vista de impresión de prueba.
        }
    }
    
    func resetWizard() {
        currentStep = .brandSelection
        selectedBrand = nil
        isPrinterReadySelected = nil
        showingTestPrintConfirmation = false
        testPrintSuccessful = nil
        showConfetti = false
    }
}