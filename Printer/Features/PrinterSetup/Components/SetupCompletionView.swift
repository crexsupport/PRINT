import SwiftUI

struct SetupCompletionView: View {
    @ObservedObject var viewModel: PrinterSetupWizardViewModel
    @State private var animateCheckmark = false
    @State private var animatePrinter = false
    
    let dismissFlow: () -> Void
    
    // Variable de estado para controlar la animación de partículas
    @State private var showParticles = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                // Partículas de Confetti
                if viewModel.showConfetti && showParticles {
                    ForEach(0..<60) { _ in
                        Circle()
                            .fill([Color.yellow, .green, .blue, .purple, .pink, .orange].randomElement()!)
                            .frame(width: .random(in: 5...15), height: .random(in: 5...15))
                            .offset(x: .random(in: -200...200), y: .random(in: -300 ... -50))
                            .opacity(.random(in: 0.5...1.0))
                            .scaleEffect(animatePrinter ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
                                .delay(.random(in: 0...0.5))
                                .repeatForever(autoreverses: false), // Animación continua
                                value: animatePrinter
                            )
                    }
                }
                
                Image(systemName: "printer.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                    .offset(y: animatePrinter ? 0 : 30)
                    .opacity(animatePrinter ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animatePrinter)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(animateCheckmark ? 1 : 0.5)
                    .opacity(animateCheckmark ? 1 : 0)
                    .offset(x: 70, y: 50)
                    .animation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10, initialVelocity: 0).delay(0.5), value: animateCheckmark)
            }
            .frame(height: 250)


            Text("Configuración de la impresora...")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .opacity(animatePrinter ? 1 : 0)
                .offset(y: animatePrinter ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animatePrinter)
            
            if viewModel.showConfetti {
                 Text("¡Tu impresora está lista!")
                    .font(.title3)
                    .foregroundColor(.green)
                    .transition(.opacity.combined(with: .scale))
            }


            Spacer()
            Spacer()

            Button(action: {
                dismissFlow()
            }) {
                Text(viewModel.showConfetti ? "Cerrar" : "Configurando...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
            }
            .disabled(!viewModel.showConfetti) // Deshabilitar hasta que la "configuración" termine
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            animatePrinter = true
            animateCheckmark = true
            // Iniciar la animación de partículas un poco después
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showParticles = true
                }
            }
        }
    }
}

#Preview {
    SetupCompletionView(
        viewModel: {
            let vm = PrinterSetupWizardViewModel()
            vm.currentStep = .finalConfirmation
            vm.showConfetti = true // Para previsualizar estado final
            return vm
        }(),
        dismissFlow: {} // Closure vacía para el preview
    )
}
