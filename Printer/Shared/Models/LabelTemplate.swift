//
//  LabelTemplate.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import Foundation

struct LabelTemplate: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

extension LabelTemplate {
    static let allTemplates: [LabelTemplate] = [
        LabelTemplate(title: "Business Card", icon: "person.crop.rectangle"),
        LabelTemplate(title: "Category", icon: "tag"),
        LabelTemplate(title: "Coffee Shop", icon: "cup.and.saucer"),
        LabelTemplate(title: "Raw Material", icon: "leaf")
    ]
}
