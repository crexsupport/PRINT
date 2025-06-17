//
//  PrinterSetupView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct PrinterSetupView: View {
    @State private var showingPrinterSetupWizard = false
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Setup and test your printer")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "printer.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                showingPrinterSetupWizard = true
            }) {
                Text("Configuration")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
        )
        .sheet(isPresented: $showingPrinterSetupWizard) {
            PrinterSetupWizardView()
        }
    }
}

#Preview {
    PrinterSetupView()
}
