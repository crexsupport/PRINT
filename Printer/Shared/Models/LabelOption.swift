//
//  LabelOption.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct LabelOption: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

extension LabelOption {
    static let allOptions: [LabelOption] = [
        LabelOption(title: "Idea", icon: "lightbulb.fill", color: .yellow),
        LabelOption(title: "Palette", icon: "paintpalette.fill", color: .orange)
    ]
}