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
            title: "Documents",
            description: "Print documents from files",
            icon: "doc.text",
            color: .blue
        ),
        PrinterFeature(
            title: "Photos",
            description: "Print photos from gallery",
            icon: "photo",
            color: .teal
        ),
        PrinterFeature(
            title: "Scanner",
            description: "Scan with phone camera",
            icon: "camera.viewfinder",
            color: .green
        ),
        PrinterFeature(
            title: "Web Pages",
            description: "Print website in full size",
            icon: "globe",
            color: .orange
        ),
        PrinterFeature(
            title: "Text Notes",
            description: "Paste or write text",
            icon: "text.alignleft",
            color: .pink
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
            title: "PDF Editor",
            description: "Delete unwanted pages",
            icon: "doc.text.below.ecg",
            color: .red
        ),
        PrinterFeature(
            title: "Image to PDF",
            description: "Convert images to PDF",
            icon: "photo.on.rectangle",
            color: .blue
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
            title: "Batch Print...",
            description: "Print multiple PDFs",
            icon: "doc.on.doc",
            color: .purple
        )
    ]
    
    static let allFeatures: [PrinterFeature] = [
        PrinterFeature(
            title: "Photos",
            description: "Print your favorite memories in high quality",
            icon: "photo.on.rectangle",
            color: .blue
        ),
        PrinterFeature(
            title: "Documents",
            description: "Print PDFs and documents with ease",
            icon: "doc.text",
            color: .green
        ),
        PrinterFeature(
            title: "Scanner",
            description: "Scan documents with your camera",
            icon: "viewfinder",
            color: .orange
        ),
        PrinterFeature(
            title: "Web Pages",
            description: "Print any webpage directly",
            icon: "globe",
            color: .purple
        ),
        PrinterFeature(
            title: "Text Notes",
            description: "Create and print text notes",
            icon: "text.alignleft",
            color: .indigo
        ),
        PrinterFeature(
            title: "PDF Editor",
            description: "Edit and modify PDF files",
            icon: "square.and.pencil",
            color: .red
        ),
        PrinterFeature(
            title: "Remove Background",
            description: "Remove backgrounds from images",
            icon: "person.crop.circle.badge.minus",
            color: .pink
        ),
        PrinterFeature(
            title: "Image to PDF",
            description: "Convert images to PDF format",
            icon: "photo.badge.plus",
            color: .cyan
        ),
        PrinterFeature(
            title: "PDF Compression",
            description: "Reduce PDF file sizes efficiently",
            icon: "archivebox",
            color: .brown
        ),
        PrinterFeature(
            title: "Printables",
            description: "Access ready-to-print templates",
            icon: "rectangle.grid.3x2",
            color: .teal
        ),
        PrinterFeature(
            title: "Batch Print",
            description: "Print multiple files at once",
            icon: "square.stack.3d.up",
            color: .mint
        )
    ]
}
