import SwiftUI

struct StepIndicatorView: View {
    let totalSteps: Int
    @Binding var currentStep: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                ZStack {
                    if step < currentStep {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    } else if step == currentStep {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                        Text("\(step)")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    } else {
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 2)
                            .frame(width: 30, height: 30)
                        Text("\(step)")
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut, value: currentStep)
    }
}

#Preview {
    StepIndicatorView(totalSteps: 4, currentStep: .constant(1))
        .padding()
}