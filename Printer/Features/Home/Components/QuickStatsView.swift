import SwiftUI

struct QuickStatsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "doc.fill",
                    title: "Documents",
                    count: "12",
                    color: .blue
                )
                
                StatCard(
                    icon: "photo.fill",
                    title: "Photos",
                    count: "28",
                    color: .green
                )
                
                StatCard(
                    icon: "printer.fill",
                    title: "Printed",
                    count: "45",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let count: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(count)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    QuickStatsView()
}