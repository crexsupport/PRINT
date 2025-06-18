import SwiftUI

struct TextNotesView: View {
    @StateObject private var viewModel = TextNotesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    // NUEVA PROPIEDAD: Para saber si se abrió desde el grid (tiene botón back)
    let showBackButton: Bool
    
    // NUEVO INICIALIZADOR
    init(showBackButton: Bool = true) {
        self.showBackButton = showBackButton
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // CONDICIONAL: Solo mostrar header con botón back si viene del grid
                if showBackButton {
                    // Custom header
                    HStack {
                        Button(action: {
                            if viewModel.currentStep == .preview {
                                viewModel.returnToInput()
                            } else {
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text(viewModel.currentStep == .preview ? "Edit" : "Back")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(viewModel.currentStep == .preview ? "Print Preview" : "Text Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Button("Back") {
                            // Empty action
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))
                }
                
                // Content
                if viewModel.currentStep == .input {
                    TextInputView(viewModel: viewModel)
                } else if viewModel.currentStep == .preview {
                    TextPreviewView(viewModel: viewModel)
                        .environmentObject(subscriptionManager)
                        .environmentObject(paywallManager)
                } else {
                    // Initial state (shouldn't happen with current logic, but keeping as fallback)
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        VStack(spacing: 12) {
                            Text("Create Text Notes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Write or paste text to create printable notes")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            // Force input step
                            viewModel.currentStep = .input
                        }) {
                            Text("Start Writing")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Preview
#Preview {
    TextNotesView()
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}
