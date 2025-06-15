//
//  PrinterApp.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

@main
struct PrinterApp: App {
    @StateObject private var scannerManager = ScannerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(scannerManager)
        }
    }
}
