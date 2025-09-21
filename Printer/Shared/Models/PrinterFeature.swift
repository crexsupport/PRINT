//
//  PrinterFeature.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct PrinterFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isComingSoon: Bool
    let isPremium: Bool
    
    init(title: String, description: String, icon: String, color: Color, isComingSoon: Bool = false, isPremium: Bool = false) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.isComingSoon = isComingSoon
        self.isPremium = isPremium
    }
}

extension PrinterFeature {
    static let mainFeatures: [PrinterFeature] = [
        PrinterFeature(
            title: String(localized: "Documents"),
            description: String(localized: "Print docs from files"),
            icon: "doc.text",
            color: Color(red: 0.15, green: 0.4, blue: 0.8) // Azul profesional
        ),
        PrinterFeature(
            title: String(localized: "Photos"),
            description: String(localized: "Print photos from gallery"),
            icon: "photo",
            color: Color(red: 0.9, green: 0.5, blue: 0.15) // Naranja profesional
        ),
        PrinterFeature(
            title: String(localized: "Scanner"),
            description: String(localized: "Scan with phone camera"),
            icon: "camera.viewfinder",
            color: Color(red: 0.15, green: 0.7, blue: 0.3) // Verde profesional
        ),
        PrinterFeature(
            title: String(localized: "Web Pages"),
            description: String(localized: "Print website in full size"),
            icon: "globe",
            color: Color(red: 0.2, green: 0.7, blue: 0.9) // Azul cielo profesional
        ),
        PrinterFeature(
            title: String(localized: "Text Notes"),
            description: String(localized: "Paste or write text"),
            icon: "text.alignleft",
            color: Color(red: 0.8, green: 0.4, blue: 0.15) // Naranja rojizo profesional
        ),
        PrinterFeature(
            title: String(localized: "Labels"),
            description: String(localized: "Create custom photo labels"),
            icon: "tag",
            color: Color(red: 0.7, green: 0.2, blue: 0.9) // Púrpura profesional
        ),
        /*
        PrinterFeature(
            title: "Remove Background",
            description: "AI background removal",
            icon: "figure.stand.line.dotted.figure.stand",
            color: .purple
        ),
        */
        PrinterFeature(
            title: String(localized: "PDF Editor"),
            description: String(localized: "Delete unwanted pages"),
            icon: "doc.text.below.ecg",
            color: Color(red: 0.8, green: 0.2, blue: 0.3) // Rojo profesional
        ),
        PrinterFeature(
            title: String(localized: "Image to PDF"),
            description: String(localized: "Convert images to PDF"),
            icon: "photo.on.rectangle",
            color: Color(red: 0.2, green: 0.6, blue: 0.8) // Azul claro profesional
        ),
        /*
        PrinterFeature(
            title: "Compress PDF",
            description: "Reduce file size up to 99%",
            icon: "doc.zipper",
            color: .green
        ),
        */
        PrinterFeature(
            title: String(localized: "Printables"),
            description: String(localized: "Ready-to-print templates"),
            icon: "rectangle.grid.3x2",
            color: Color(red: 0.2, green: 0.8, blue: 0.7) // Color turquesa
        ),
        PrinterFeature(
            title: String(localized: "Batch Print"),
            description: String(localized: "Print multiple PDFs"),
            icon: "doc.on.doc",
            color: Color(red: 0.4, green: 0.3, blue: 0.7) // Púrpura azulado profesional
        )
    ]
    
    static let allFeatures: [PrinterFeature] = [
        PrinterFeature(
            title: String(localized: "Photos"),
            description: String(localized: "Print your favorite memories in high quality"),
            icon: "photo.on.rectangle",
            color: .blue
        ),
        PrinterFeature(
            title: String(localized: "Documents"),
            description: String(localized: "Print PDFs and documents with ease"),
            icon: "doc.text",
            color: .green
        ),
        PrinterFeature(
            title: String(localized: "Scanner"),
            description: String(localized: "Scan documents with your camera"),
            icon: "viewfinder",
            color: .orange
        ),
        PrinterFeature(
            title: String(localized: "Web Pages"),
            description: String(localized: "Print any webpage directly"),
            icon: "globe",
            color: .purple
        ),
        PrinterFeature(
            title: String(localized: "Text Notes"),
            description: String(localized: "Create and print text notes"),
            icon: "text.alignleft",
            color: .indigo
        ),
        PrinterFeature(
            title: String(localized: "PDF Editor"),
            description: String(localized: "Edit and modify PDF files"),
            icon: "square.and.pencil",
            color: .red
        ),
        PrinterFeature(
            title: String(localized: "Remove Background"),
            description: String(localized: "Remove backgrounds from images"),
            icon: "person.crop.circle.badge.minus",
            color: .pink
        ),
        PrinterFeature(
            title: String(localized: "Image to PDF"),
            description: String(localized: "Convert images to PDF format"),
            icon: "photo.badge.plus",
            color: .cyan
        ),
        PrinterFeature(
            title: String(localized: "PDF Compression"),
            description: String(localized: "Reduce PDF file sizes efficiently"),
            icon: "archivebox",
            color: .brown
        ),
        PrinterFeature(
            title: String(localized: "Printables"),
            description: String(localized: "Access ready-to-print templates"),
            icon: "rectangle.grid.3x2",
            color: .teal
        ),
        PrinterFeature(
            title: String(localized: "Batch Print"),
            description: String(localized: "Print multiple files at once"),
            icon: "square.stack.3d.up",
            color: .mint
        )
    ]
}