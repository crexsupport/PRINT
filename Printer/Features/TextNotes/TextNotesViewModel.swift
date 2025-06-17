import SwiftUI
import Foundation
import UIKit
import PDFKit
import CoreText
import Combine

class TextNotesViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var currentStep: TextNotesStep = .input
    @Published var showingPreview = false
        
    // Computed properties
    var hasText: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var characterCount: Int {
        inputText.count
    }
    
    var wordCount: Int {
        let words = inputText.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    var formattedText: String {
        return inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func showPreview() {
        guard hasText else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .preview
            showingPreview = true
        }
    }
    
    func returnToInput() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .input
            showingPreview = false
        }
    }
    
    func generateShareText() -> URL {
        return generatePDF()
    }
    
    func generatePDF() -> URL {
        let pdfMetaData = [
            kCGPDFContextCreator: "Printer App",
            kCGPDFContextAuthor: "Text Notes",
            kCGPDFContextTitle: "Text Note"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A4 size in points (72 points per inch)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            let margin: CGFloat = 50 // Back to 50pt margins like the PDF shows
            let contentRect = CGRect(
                x: margin,
                y: margin,
                width: pageRect.width - (margin * 2),
                height: pageRect.height - (margin * 2)
            )
            
            // Text attributes - clean and simple
            let textFont = UIFont.systemFont(ofSize: 11) // Match preview
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineSpacing = 1.5 // Match preview reduced spacing
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            // Use CoreText for proper text layout (more reliable)
            let attributedText = NSAttributedString(string: inputText, attributes: textAttributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
            
            var textRange = CFRange(location: 0, length: 0)
            var pageNumber = 1
            
            while textRange.location < attributedText.length {
                // Begin new page
                context.beginPage()
                
                // Create frame for text content
                let framePath = CGPath(rect: contentRect, transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, textRange, framePath, nil)
                
                // Draw the text
                let cgContext = context.cgContext
                cgContext.saveGState()
                
                // Flip coordinate system for proper text rendering
                cgContext.translateBy(x: 0, y: pageRect.height)
                cgContext.scaleBy(x: 1, y: -1)
                
                // Draw text frame
                CTFrameDraw(frame, cgContext)
                
                cgContext.restoreGState()
                
                // Get the range of text that was drawn
                let frameRange = CTFrameGetVisibleStringRange(frame)
                textRange.location += frameRange.length
                textRange.length = attributedText.length - textRange.location
                
                pageNumber += 1
                
                // Safety check to prevent infinite loop
                if frameRange.length == 0 || pageNumber > 100 {
                    break
                }
            }
        }
        
        // Save to temporary directory
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "TextNote_\(Date().timeIntervalSince1970).pdf"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            let fallbackURL = tempDirectory.appendingPathComponent("TextNote_fallback.txt")
            try? inputText.write(to: fallbackURL, atomically: true, encoding: .utf8)
            return fallbackURL
        }
    }
    
    func getPageCount() -> Int {
        guard !inputText.isEmpty else { return 1 }
        
        // Use exact same calculation as PDF generation
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11), // Match preview
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 1.5 // Match preview reduced spacing
                style.alignment = .left
                return style
            }()
        ]
        
        let attributedText = NSAttributedString(string: inputText, attributes: textAttributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        // Same dimensions as PDF: A4 with 40pt margins (to match preview padding)
        let contentWidth: CGFloat = 515.2  // 595.2 - 80 (40pt margins each side)
        let contentHeight: CGFloat = 761.8 // 841.8 - 80 (40pt margins top/bottom)
        let contentRect = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        
        var pageCount = 0
        var textRange = CFRange(location: 0, length: 0)
        
        while textRange.location < attributedText.length {
            let framePath = CGPath(rect: contentRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, textRange, framePath, nil)
            let frameRange = CTFrameGetVisibleStringRange(frame)
            
            pageCount += 1
            textRange.location += frameRange.length
            textRange.length = attributedText.length - textRange.location
            
            // Safety check
            if frameRange.length == 0 || pageCount > 100 {
                break
            }
        }
        
        return max(1, pageCount)
    }
    
    func getTextForPage(_ pageIndex: Int) -> String {
        guard !inputText.isEmpty else { return "" }
        
        // Use exact same calculation as PDF generation
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11), // Match preview
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 1.5 // Match preview reduced spacing
                style.alignment = .left
                return style
            }()
        ]
        
        let attributedText = NSAttributedString(string: inputText, attributes: textAttributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        // Same dimensions as PDF: A4 with 40pt margins (to match preview padding)
        let contentWidth: CGFloat = 515.2  // 595.2 - 80 (40pt margins each side)
        let contentHeight: CGFloat = 761.8 // 841.8 - 80 (40pt margins top/bottom)
        let contentRect = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        
        var currentPage = 0
        var textRange = CFRange(location: 0, length: 0)
        
        while textRange.location < attributedText.length && currentPage <= pageIndex {
            let framePath = CGPath(rect: contentRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, textRange, framePath, nil)
            let frameRange = CTFrameGetVisibleStringRange(frame)
            
            if currentPage == pageIndex {
                // This is the page we want - return exact text that fits
                let pageRange = NSRange(location: textRange.location, length: frameRange.length)
                if pageRange.location + pageRange.length <= attributedText.length {
                    return attributedText.attributedSubstring(from: pageRange).string
                }
            }
            
            currentPage += 1
            textRange.location += frameRange.length
            textRange.length = attributedText.length - textRange.location
            
            // Safety check
            if frameRange.length == 0 || currentPage > 100 {
                break
            }
        }
        
        return ""
    }
    
    func printText() {
        guard hasText else { return }
        
        // Use main queue and add safety checks
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let printController = UIPrintInteractionController.shared
            
            let printFormatter = UISimpleTextPrintFormatter(text: self.formattedText)
            printFormatter.contentInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
            printFormatter.font = UIFont.systemFont(ofSize: 12)
            printFormatter.color = UIColor.black
            
            let printInfo = UIPrintInfo.printInfo()
            printInfo.outputType = .general
            printInfo.jobName = "Text Note - \(Date().formatted(date: .abbreviated, time: .shortened))"
            printInfo.orientation = .portrait
            
            printController.printInfo = printInfo
            printController.printFormatter = printFormatter
            
            printController.present(animated: true) { (controller, completed, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Print error: \(error.localizedDescription)")
                        // Could show user alert here if needed
                    } else if completed {
                        print("Print completed successfully")
                        // Could show success message if needed
                    } else {
                        print("Print cancelled by user")
                    }
                }
            }
        }
    }
    
    func reset() {
        withAnimation(.easeInOut(duration: 0.3)) {
            inputText = ""
            currentStep = .input
            showingPreview = false
        }
    }
}

// MARK: - Supporting Types
enum TextNotesStep {
    case input
    case preview
}

enum TextNotesFontStyle: String, CaseIterable {
    case body = "Body"
    case headline = "Headline"
    case title = "Title"
    case caption = "Caption"
    
    var font: Font {
        switch self {
        case .body:
            return .body
        case .headline:
            return .headline
        case .title:
            return .title2
        case .caption:
            return .caption
        }
    }
}
