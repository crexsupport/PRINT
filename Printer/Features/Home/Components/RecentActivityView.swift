import SwiftUI

struct RecentActivityView: View {
    @StateObject private var activityManager = RecentActivityManager()
    @State private var showingAllActivities = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !activityManager.activities.isEmpty {
                    Button("See All") {
                        showingAllActivities = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if activityManager.activities.isEmpty {
                emptyStateView
            } else {
                activitiesListView
            }
        }
        .sheet(isPresented: $showingAllActivities) {
            AllActivitiesView(activityManager: activityManager)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Your printing history will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    private var activitiesListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(activityManager.recentActivities) { activity in
                    RecentActivityCard(activity: activity)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - All Activities View
struct AllActivitiesView: View {
    @ObservedObject var activityManager: RecentActivityManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(activityManager.activities) { activity in
                    AllActivityRow(activity: activity)
                }
                .onDelete(perform: deleteActivities)
            }
            .navigationTitle("All Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !activityManager.activities.isEmpty {
                        Button("Clear All") {
                            activityManager.clearAllActivities()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func deleteActivities(offsets: IndexSet) {
        for index in offsets {
            activityManager.removeActivity(activityManager.activities[index])
        }
    }
}

struct AllActivityRow: View {
    let activity: PrinterRecentActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundColor(activity.type.color)
                .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(activity.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let fileSize = activity.fileSize {
                        Text("• \(fileSize)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let pages = activity.pages {
                        Text("• \(pages) page\(pages == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(activity.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            Image(systemName: activity.status.icon)
                .font(.title3)
                .foregroundColor(activity.status.color)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecentActivityView()
}
