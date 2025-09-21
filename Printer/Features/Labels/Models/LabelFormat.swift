//
//  LabelFormat.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import Foundation

struct LabelFormat: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let labelsPerSheet: Int
    let dimensions: String
    let columns: Int
    let rows: Int
    
    // Grid layout information
    var gridColumns: Int { columns }
    var gridRows: Int { rows }
}

extension LabelFormat {
    static let allFormats: [LabelFormat] = [
        LabelFormat(
            title: String(localized: "2 per sheet"),
            subtitle: "1 x 1.5",
            labelsPerSheet: 2,
            dimensions: "1 x 1.5",
            columns: 1,
            rows: 2
        ),
        LabelFormat(
            title: String(localized: "4 per sheet"),
            subtitle: "1 x 2.5",
            labelsPerSheet: 4,
            dimensions: "1 x 2.5",
            columns: 2,
            rows: 2
        ),
        LabelFormat(
            title: String(localized: "6 per sheet"),
            subtitle: "1 x 2.5",
            labelsPerSheet: 6,
            dimensions: "1 x 2.5",
            columns: 2,
            rows: 3
        ),
        LabelFormat(
            title: String(localized: "8 per sheet"),
            subtitle: "1 x 1.5",
            labelsPerSheet: 8,
            dimensions: "1 x 1.5",
            columns: 2,
            rows: 4
        ),
        LabelFormat(
            title: String(localized: "15 per sheet"),
            subtitle: "",
            labelsPerSheet: 15,
            dimensions: "",
            columns: 3,
            rows: 5
        ),
        LabelFormat(
            title: String(localized: "18 per sheet"),
            subtitle: "",
            labelsPerSheet: 18,
            dimensions: "",
            columns: 3,
            rows: 6
        )
    ]
}