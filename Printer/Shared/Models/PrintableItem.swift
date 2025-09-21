//
//  PrintableItem.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI
import Foundation

struct PrintableItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let imageName: String
    let category: PrintableCategory
    let pdfFileName: String
    let thumbnailURL: URL?
    
    // Inicializador desde URL (para cuando tengamos las carpetas)
    init(pdfURL: URL, category: PrintableCategory) {
        self.pdfFileName = pdfURL.lastPathComponent
        self.title = PrintableItem.generateTitle(from: pdfURL.lastPathComponent)
        self.imageName = PrintableItem.generateImageName(from: pdfURL.lastPathComponent)
        self.category = category
        // IMPORTANTE: Almacenar la ruta relativa completa
        self.thumbnailURL = pdfURL
    }
    
    // Inicializador simple para datos de ejemplo
    init(title: String, category: PrintableCategory) {
        self.title = title
        self.imageName = title.lowercased().replacingOccurrences(of: " ", with: "_") + "_thumb"
        self.category = category
        // IMPORTANTE: Incluir carpeta en el filename
        self.pdfFileName = "\(category.folderName)/\(title.lowercased().replacingOccurrences(of: " ", with: "_")).pdf"
        self.thumbnailURL = nil
    }
    
    // Nueva función para obtener el path relativo del PDF
    var pdfResourcePath: String {
        if let url = thumbnailURL {
            // Si tenemos la URL original, extraer el path relativo
            let pathComponents = url.pathComponents
            if let resourceIndex = pathComponents.firstIndex(where: { $0.contains("Resources") || $0 == category.folderName }) {
                let relevantComponents = Array(pathComponents[resourceIndex...])
                return relevantComponents.joined(separator: "/").replacingOccurrences(of: ".pdf", with: "")
            }
        }
        
        // Fallback: usar categoría + nombre de archivo
        let fileName = pdfFileName.replacingOccurrences(of: ".pdf", with: "")
        return "\(category.folderName)/\(fileName)"
    }
    
    // Convierte "birthday_card_1.pdf" -> "Birthday Card 1"
    private static func generateTitle(from filename: String) -> String {
        let nameWithoutExtension = filename.replacingOccurrences(of: ".pdf", with: "")
        let words = nameWithoutExtension.components(separatedBy: "_")
        return words.map { $0.capitalized }.joined(separator: " ")
    }
    
    // Genera nombre para thumbnail: "birthday_card_1.pdf" -> "birthday_card_1_thumb"
    private static func generateImageName(from filename: String) -> String {
        return filename.replacingOccurrences(of: ".pdf", with: "_thumb")
    }
}

enum PrintableCategory: String, CaseIterable {
    case all = "All"
    case birthdays = "Birthdays"
    case calendars = "Calendars"
    case planners = "Planners"
    case coloring = "Coloring"
    
    var displayName: String { 
        switch self {
        case .all:
            return String(localized: "All")
        case .birthdays:
            return String(localized: "Birthdays")
        case .calendars:
            return String(localized: "Calendars")
        case .planners:
            return String(localized: "Planners")
        case .coloring:
            return String(localized: "Coloring")
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .birthdays: return "gift"
        case .calendars: return "calendar"
        case .planners: return "doc.text"
        case .coloring: return "paintbrush"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .birthdays: return .pink
        case .calendars: return .green
        case .planners: return .orange
        case .coloring: return .purple
        }
    }
    
    var folderName: String {
        return self.rawValue
    }
    
    var sortOrder: Int {
        switch self {
        case .all: return 0
        case .calendars: return 1
        case .birthdays: return 2
        case .planners: return 3
        case .coloring: return 4
        }
    }
}

// Manager para cargar automáticamente los printables
class PrintablesManager: ObservableObject {
    @Published var printables: [PrintableItem] = []
    
    init() {
        loadPrintables()
    }
    
    private func loadPrintables() {
        var allPrintables: [PrintableItem] = []
        
        // Método 1: Buscar en carpetas específicas usando subdirectory
        for category in PrintableCategory.allCases where category != .all {
            if let categoryURL = Bundle.main.url(forResource: "", withExtension: nil, subdirectory: category.folderName) {
                let pdfFiles = getPDFFiles(in: categoryURL)
                for pdfURL in pdfFiles {
                    let printable = PrintableItem(pdfURL: pdfURL, category: category)
                    allPrintables.append(printable)
                }
            }
        }
        
        // Método 2: Si no encuentra nada, buscar recursivamente en todo el bundle
        if allPrintables.isEmpty {
            guard let resourceURL = Bundle.main.resourceURL else {
                self.printables = createSampleData()
                return
            }
            
            let enumerator = FileManager.default.enumerator(at: resourceURL, 
                                                          includingPropertiesForKeys: [.isRegularFileKey],
                                                          options: [.skipsHiddenFiles])
            
            while let url = enumerator?.nextObject() as? URL {
                if url.pathExtension.lowercased() == "pdf" {
                    let category = determineCategoryFromPDF(url)
                    let printable = PrintableItem(pdfURL: url, category: category)
                    allPrintables.append(printable)
                }
            }
        }
        
        if allPrintables.isEmpty {
            self.printables = createSampleData()
        } else {
            self.printables = allPrintables
        }
    }
    
    private func getPDFFiles(in directory: URL) -> [URL] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            return contents.filter { $0.pathExtension.lowercased() == "pdf" }
        } catch {
            return []
        }
    }
    
    private func determineCategoryFromPDF(_ url: URL) -> PrintableCategory {
        let pathComponents = url.pathComponents
        
        // Buscar la carpeta padre en el path
        for component in pathComponents.reversed() {
            switch component.lowercased() {
            case "birthdays": return .birthdays
            case "calendars": return .calendars  
            case "planners": return .planners
            case "coloring": return .coloring
            default: continue
            }
        }
        
        // Fallback por nombre de archivo
        let fileName = url.lastPathComponent.lowercased()
        if fileName.contains("birthday") { return .birthdays }
        if fileName.contains("calendar") { return .calendars }
        if fileName.contains("planner") { return .planners }
        if fileName.contains("coloring") { return .coloring }
        
        return .birthdays
    }
    
    // Datos temporales de ejemplo
    private func createSampleData() -> [PrintableItem] {
        return [
            // Birthday Cards
            PrintableItem(title: "Happy Birthday Card", category: .birthdays),
            PrintableItem(title: "Birthday Wishes", category: .birthdays),
            PrintableItem(title: "Celebration Card", category: .birthdays),
            
            // Calendars
            PrintableItem(title: "January 2025", category: .calendars),
            PrintableItem(title: "2025 Full Year", category: .calendars),
            PrintableItem(title: "Monthly Planner", category: .calendars),
            
            // Planners
            PrintableItem(title: "Weekly Planner", category: .planners),
            PrintableItem(title: "Success Planner", category: .planners),
            PrintableItem(title: "Meal Planner", category: .planners),
            
            // Coloring
            PrintableItem(title: "Mandala Design", category: .coloring),
            PrintableItem(title: "Nature Scenes", category: .coloring),
            PrintableItem(title: "Abstract Art", category: .coloring)
        ]
    }
    
    func printables(for category: PrintableCategory) -> [PrintableItem] {
        if category == .all {
            return printables
        }
        return printables.filter { $0.category == category }
    }
}