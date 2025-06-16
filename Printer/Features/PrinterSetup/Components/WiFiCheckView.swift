import SwiftUI

struct WiFiCheckOptionCard: View {
    let title: String
    let description: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 50, height: 50)
                    .background( (isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)).clipShape(Circle()) )


                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(nil) // Allow multiline
                        .fixedSize(horizontal: false, vertical: true) // Important for multiline text
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle()) // Para quitar el efecto de botón por defecto dentro de la card
    }
}


struct WiFiCheckView: View {
    @ObservedObject var viewModel: PrinterSetupWizardViewModel

    var body: some View {
        VStack(spacing: 25) {
            Spacer(minLength: 10)
            
            WiFiCheckOptionCard(
                title: "La impresora está lista",
                description: "La impresora ya está en espera y conectada a la misma red Wi-Fi que el iPhone.",
                iconName: "wifi.circle.fill",
                isSelected: viewModel.isPrinterReadySelected == true,
                action: { viewModel.selectPrinterStatus(isReady: true) }
            )
            
            WiFiCheckOptionCard(
                title: "La impresora no está lista",
                description: "La impresora no puede conectarse a la red o no sabe cómo configurarla.",
                iconName: "wifi.exclamationmark.circle.fill",
                isSelected: viewModel.isPrinterReadySelected == false,
                action: { viewModel.selectPrinterStatus(isReady: false) }
            )
            
            Spacer()
            
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isPrinterReadySelected == nil ? Color.gray.opacity(0.5) : Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(viewModel.isPrinterReadySelected == nil ? 0 : 0.3), radius: 5, y: 3)
            }
            .disabled(viewModel.isPrinterReadySelected == nil)
            .padding(.bottom)
        }
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    WiFiCheckView(viewModel: PrinterSetupWizardViewModel())
}