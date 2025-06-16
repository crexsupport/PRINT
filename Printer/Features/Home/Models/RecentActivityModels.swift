import SwiftUI
import Foundation

struct PrinterRecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let type: ActivityType
    let date: Date
    let status: ActivityStatus
    let fileSize: String?
    let pages: Int?
    
    enum ActivityType: String, CaseIterable {
        case document = "Document"
        case photo = "Photo"
        case scan = "Scan"
        case pdf = "PDF"
        case textNote = "Text Note"
        case webPage = "Web Page"
        case batch = "Batch Print"
        
        var icon: String {
            switch self {
            case .document: return "doc.fill"
            case .photo: return "photo.fill"
            case .scan: return "camera.viewfinder"
            case .pdf: return "doc.text.fill"
            case .textNote: return "note.text"
            case .webPage: return "globe"
            case .batch: return "square.stack.3d.up.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .document: return .blue
            case .photo: return .green
            case .scan: return .orange
            case .pdf: return .red
            case .textNote: return .purple
            case .webPage: return .cyan
            case .batch: return .indigo
            }
        }
    }
    
    enum ActivityStatus {
        case completed
        case failed
        case inProgress
        
        var icon: String {
            switch self {
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .inProgress: return "clock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .completed: return .green
            case .failed: return .red
            case .inProgress: return .orange
            }
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

class RecentActivityManager: ObservableObject {
    @Published var activities: [PrinterRecentActivity] = []
    
    private let userDefaults = UserDefaults.standard
    private let activitiesKey = "printer_recent_activities"
    
    init() {
        loadActivities()
        // If no activities found, load sample data for demo
        if activities.isEmpty {
            loadSampleData()
        }
    }
    
    func addActivity(_ activity: PrinterRecentActivity) {
        activities.insert(activity, at: 0)
        // Keep only last 50 activities
        if activities.count > 50 {
            activities = Array(activities.prefix(50))
        }
        saveActivities()
    }
    
    func addActivity(title: String, type: PrinterRecentActivity.ActivityType, status: PrinterRecentActivity.ActivityStatus = .completed, fileSize: String? = nil, pages: Int? = nil) {
        let activity = PrinterRecentActivity(
            title: title,
            type: type,
            date: Date(),
            status: status,
            fileSize: fileSize,
            pages: pages
        )
        addActivity(activity)
    }
    
    func removeActivity(_ activity: PrinterRecentActivity) {
        activities.removeAll { $0.id == activity.id }
        saveActivities()
    }
    
    func clearAllActivities() {
        activities.removeAll()
        saveActivities()
    }
    
    var recentActivities: [PrinterRecentActivity] {
        Array(activities.prefix(5))
    }
    
    private func loadActivities() {
        if let data = userDefaults.data(forKey: activitiesKey),
           let decoded = try? JSONDecoder().decode([CodableActivity].self, from: data) {
            activities = decoded.map { $0.toPrinterActivity() }
        }
    }
    
    private func saveActivities() {
        let codableActivities = activities.map { CodableActivity(from: $0) }
        if let encoded = try? JSONEncoder().encode(codableActivities) {
            userDefaults.set(encoded, forKey: activitiesKey)
        }
    }
    
    private func loadSampleData() {
        let sampleActivities = [
            PrinterRecentActivity(
                title: "Meeting_Notes.pdf",
                type: .pdf,
                date: Date().addingTimeInterval(-7200),
                status: .completed,
                fileSize: "2.3 MB",
                pages: 5
            ),
            PrinterRecentActivity(
                title: "Family_Photos",
                type: .photo,
                date: Date().addingTimeInterval(-86400),
                status: .completed,
                fileSize: "15.8 MB",
                pages: 12
            ),
            PrinterRecentActivity(
                title: "Receipt_Scan",
                type: .scan,
                date: Date().addingTimeInterval(-259200),
                status: .completed,
                fileSize: "1.2 MB",
                pages: 1
            ),
            PrinterRecentActivity(
                title: "Shopping List",
                type: .textNote,
                date: Date().addingTimeInterval(-345600),
                status: .completed,
                fileSize: nil,
                pages: 1
            ),
            PrinterRecentActivity(
                title: "Google Search Results",
                type: .webPage,
                date: Date().addingTimeInterval(-432000),
                status: .completed,
                fileSize: "890 KB",
                pages: 3
            )
        ]
        
        activities = sampleActivities
        saveActivities()
    }
}

// MARK: - Codable wrapper for persistence
private struct CodableActivity: Codable {
    let id: String
    let title: String
    let type: String
    let date: Date
    let status: String
    let fileSize: String?
    let pages: Int?
    
    init(from activity: PrinterRecentActivity) {
        self.id = activity.id.uuidString
        self.title = activity.title
        self.type = activity.type.rawValue
        self.date = activity.date
        self.status = {
            switch activity.status {
            case .completed: return "completed"
            case .failed: return "failed"
            case .inProgress: return "inProgress"
            }
        }()
        self.fileSize = activity.fileSize
        self.pages = activity.pages
    }
    
    func toPrinterActivity() -> PrinterRecentActivity {
        PrinterRecentActivity(
            title: title,
            type: PrinterRecentActivity.ActivityType(rawValue: type) ?? .document,
            date: date,
            status: {
                switch status {
                case "completed": return .completed
                case "failed": return .failed
                case "inProgress": return .inProgress
                default: return .completed
                }
            }(),
            fileSize: fileSize,
            pages: pages
        )
    }
}
