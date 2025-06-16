import SwiftUI

struct RecentActivityCard: View {
    let activity: PrinterRecentActivity
    let onRemove: (() -> Void)?
    
    init(activity: PrinterRecentActivity, onRemove: (() -> Void)? = nil) {
        self.activity = activity
        self.onRemove = onRemove
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with type icon and status
            HStack {
                Image(systemName: activity.type.icon)
                    .font(.title3)
                    .foregroundColor(activity.type.color)
                
                Spacer()
                
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: activity.status.icon)
                        .font(.caption)
                        .foregroundColor(activity.status.color)
                }
            }
            
            // Title
            Text(activity.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Bottom info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.type.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let pages = activity.pages {
                        Text("\(pages) page\(pages == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(activity.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 140, height: 110)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    RecentActivityCard(
        activity: PrinterRecentActivity(
            title: "Test Document.pdf",
            type: .pdf,
            date: Date().addingTimeInterval(-7200),
            status: .completed,
            fileSize: "2.3 MB",
            pages: 5
        )
    )
    .padding()
}
