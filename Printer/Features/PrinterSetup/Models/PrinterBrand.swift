import SwiftUI

struct PrinterBrand: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let logoName: String // Nombre del asset de la imagen del logo
}

extension PrinterBrand {
    static let supportedBrands: [PrinterBrand] = [
        PrinterBrand(name: "HP", logoName: "logo_hp"),
        PrinterBrand(name: "Epson", logoName: "logo_epson"),
        PrinterBrand(name: "Canon", logoName: "logo_canon"),
        PrinterBrand(name: "Brother", logoName: "logo_brother"), // Asumiendo "Hermano" es Brother
        PrinterBrand(name: "Xerox", logoName: "logo_xerox"), // Asumiendo "fotocopia" se refiere a Xerox o una genérica
        PrinterBrand(name: "Other", logoName: "logo_other")
    ]
}