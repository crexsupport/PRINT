import SwiftUI

struct BrandSelectionView: View {
    @ObservedObject var viewModel: PrinterSetupWizardViewModel
    let brands = PrinterBrand.supportedBrands

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Seleccione su marca de impresora")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            List(brands) { brand in
                Button(action: {
                    viewModel.selectBrand(brand)
                }) {
                    HStack(spacing: 15) {
                        Image(brand.logoName) // Asegúrate de tener estos assets
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text(brand.name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if viewModel.selectedBrand?.id == brand.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                }
                .listRowBackground(viewModel.selectedBrand?.id == brand.id ? Color.blue.opacity(0.1) : Color.clear)
            }
            .listStyle(InsetGroupedListStyle()) // O PlainListStyle si prefieres
            
            Spacer()
            
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedBrand == nil ? Color.gray.opacity(0.5) : Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(viewModel.selectedBrand == nil ? 0 : 0.3), radius: 5, y: 3)
            }
            .disabled(viewModel.selectedBrand == nil)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    BrandSelectionView(viewModel: PrinterSetupWizardViewModel())
}