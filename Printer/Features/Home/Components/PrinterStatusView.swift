import SwiftUI

struct PrinterStatusView: View {
    @State private var connectionStatus: ConnectionStatus = .connected
    @State private var printerName = "HP OfficeJet Pro 9015"
    @State private var inkLevel = 75
    @State private var paperLevel = 80
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case offline
        case error
        
        var title: String {
            switch self {
            case .connected:
                return "Connected"
            case .disconnected:
                return "Disconnected"
            case .offline:
                return "Offline"
            case .error:
                return "Error"
            }
        }
        
        var icon: String {
            switch self {
            case .connected:
                return "checkmark.circle.fill"
            case .disconnected:
                return "wifi.slash"
            case .offline:
                return "power.circle"
            case .error:
                return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .connected:
                return .green
            case .disconnected:
                return .orange
            case .offline:
                return .gray
            case .error:
                return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Printer Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(printerName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Image(systemName: connectionStatus.icon)
                        .font(.caption)
                        .foregroundColor(connectionStatus.color)
                    
                    Text(connectionStatus.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(connectionStatus.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(connectionStatus.color.opacity(0.1))
                .cornerRadius(8)
            }
            
            if connectionStatus == .connected {
                // Printer info when connected
                HStack(spacing: 16) {
                    // Ink level
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Ink")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text("\(inkLevel)%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Paper level
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Paper")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text("\(paperLevel)%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Quick action
                    Button {
                        // Test print action
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "printer.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Test")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                // Setup button when not connected
                Button {
                    // Navigate to printer setup
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Setup Printer")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    PrinterStatusView()
        .padding()
}
