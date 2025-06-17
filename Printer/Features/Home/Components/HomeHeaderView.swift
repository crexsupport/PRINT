//
//  HomeHeaderView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct HomeHeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "crown.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            Spacer()
            
            Text("Smart Printer")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("+")
                .font(.title2)
                .fontWeight(.light)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

#Preview {
    HomeHeaderView()
}
