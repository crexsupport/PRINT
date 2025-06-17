import SwiftUI

struct PrinterSetupWizardView: View {
    @StateObject private var viewModel = PrinterSetupWizardViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                StepIndicatorView(
                    totalSteps: PrinterSetupWizardStep.allCases.count,
                    currentStep: .constant(viewModel.currentStep.rawValue)
                )
                .padding(.vertical)
                .background(Color(.systemBackground)) // Un fondo para separarlo del contenido
                
                // Divisor sutil
                Divider()

                currentStepView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep != .brandSelection && viewModel.currentStep != .finalConfirmation {
                        Button("Atrás") {
                            viewModel.previousStep()
                        }
                    } else if viewModel.currentStep == .brandSelection {
                         Button("Cancelar") {
                            dismiss()
                        }
                    }
                }
                 ToolbarItem(placement: .navigationBarTrailing) {
                     // Botón de Cerca para la pantalla final, si no se maneja en SetupCompletionView
                     if viewModel.currentStep == .finalConfirmation && viewModel.showConfetti {
                         Button("Cerrar") {
                             dismiss()
                         }
                     }
                 }
            }
            .interactiveDismissDisabled(viewModel.currentStep != .finalConfirmation || !viewModel.showConfetti) // Evitar cierre accidental
        }
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .brandSelection:
            BrandSelectionView(viewModel: viewModel)
        case .wifiCheck:
            WiFiCheckView(viewModel: viewModel)
        case .testPrint:
            TestPrintView(viewModel: viewModel)
        case .finalConfirmation:
            SetupCompletionView(viewModel: viewModel, dismissFlow: { dismiss() })
        }
    }
}

#Preview {
    PrinterSetupWizardView()
}
