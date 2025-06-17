//
//  PrintablesView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct PrintablesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Printables")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Your saved printable documents will appear here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    PrintablesView()
}
