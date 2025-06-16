import SwiftUI

struct RemoveBackgroundSelectionView: View {
    @ObservedObject var viewModel: RemoveBackgroundViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    // Header section
                    headerSection
                    
                    // Source selection section
                    sourceSelectionSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // AI Magic Icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.05)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: Date().timeIntervalSince1970)
                
                Image(systemName: "figure.stand.line.dotted.figure.stand")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Sparkle effects
                ForEach(0..<6) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(.purple.opacity(0.6))
                        .offset(
                            x: cos(Double(index) * .pi / 3) * 70,
                            y: sin(Double(index) * .pi / 3) * 70
                        )
                        .scaleEffect(0.5 + sin(Date().timeIntervalSince1970 * 3 + Double(index)) * 0.3)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: Date().timeIntervalSince1970)
                }
            }
            
            VStack(spacing: 12) {
                Text("AI Background Removal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Automatically remove backgrounds from your photos using advanced AI technology")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.top, 20)
    }
    
    private var sourceSelectionSection: some View {
        VStack(spacing: 20) {
            Text("Select Image Source")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Photo Gallery Option
                Button {
                    viewModel.selectImageSource(.gallery)
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Photo Gallery")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Choose from your saved photos")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Camera Option
                Button {
                    viewModel.selectImageSource(.camera)
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Take Photo")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Capture a new photo with camera")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Features info
            featuresSection
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("✨ Features")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FeatureInfoCard(
                    icon: "cpu",
                    title: "AI Powered",
                    subtitle: "Advanced ML algorithms"
                )
                
                FeatureInfoCard(
                    icon: "speedometer",
                    title: "Fast Processing",
                    subtitle: "Results in seconds"
                )
                
                FeatureInfoCard(
                    icon: "paintbrush.pointed",
                    title: "High Quality",
                    subtitle: "Professional results"
                )
                
                FeatureInfoCard(
                    icon: "drop.fill",
                    title: "Shadow Effects",
                    subtitle: "Optional drop shadows"
                )
            }
        }
        .padding(.top, 20)
    }
}

struct FeatureInfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.purple)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.05))
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    RemoveBackgroundSelectionView(viewModel: RemoveBackgroundViewModel())
}
