//
//  OnboardingView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 16/6/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var hasShownATTPrompt = false
    @StateObject private var attManager = ATTManager()
    @Environment(\.requestReview) private var requestReview
    let onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "onb_1",
            title: String(localized: "Print Documents & Photos"),
            subtitle: "",
            description: String(localized: "Print documents and photos from your device wirelessly to any compatible printer."),
            isReview: false
        ),
        OnboardingPage(
            image: "onb_2",
            title: String(localized: "Advanced Document Editing"),
            subtitle: "",
            description: String(localized: "Edit, compress, and organize your PDFs with professional-grade tools."),
            isReview: false
        ),
        OnboardingPage(
            image: "onb_3",
            title: String(localized: "Wireless Printing Made Easy"),
            subtitle: "",
            description: String(localized: "Connect to any printer instantly. No setup required, just print and go."),
            isReview: false
        ),
        OnboardingPage(
            image: "",
            title: String(localized: "Love Printer?"),
            subtitle: "",
            description: String(localized: "Join thousands of professionals who trust our printing solutions for their daily workflow needs."),
            isReview: true
        )
    ]
    
    var body: some View {
        ZStack {
            // More subtle blue gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.blue.opacity(0.04),
                    Color.white,
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if pages[currentPage].isReview {
                // Special layout for reviews page
                VStack(spacing: 0) {
                    // Reviews content - takes most of the space
                    ReviewsPageView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    // Page indicators for review page - matching reference style
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            if index == currentPage {
                                // Active indicator - elongated
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: 24, height: 8)
                            } else {
                                // Inactive indicators - small circles
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .padding(.bottom, 140)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            } else {
                // Normal layout for onboarding pages
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)
                    
                    // Image container with fixed height to keep text position consistent
                    VStack(spacing: 0) {
                        // Fixed container for image area (360px to accommodate largest image)
                        ZStack {
                            // Animated content for each page
                            ForEach(0..<pages.count, id: \.self) { index in
                                if index == currentPage && !pages[index].isReview {
                                    VStack(spacing: 30) {
                                        // Image section
                                        Group {
                                            if pages[index].image == "onb_2" {
                                                Image(pages[index].image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 320, height: 320)
                                                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
                                            } else {
                                                Image(pages[index].image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 280, height: 280)
                                                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
                                            }
                                        }
                                        
                                        // Text content
                                        VStack(spacing: 12) {
                                            Text(pages[index].title)
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.horizontal, 32)
                                            
                                            Text(pages[index].description)
                                                .font(.system(size: 16))
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .lineSpacing(2)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.horizontal, 40)
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                                }
                            }
                        }
                        .frame(height: 500) // Increased height to accommodate text
                        
                        Spacer()
                            .frame(minHeight: 30) // Reduced since text is now inside the container
                    }
                    
                    // Page indicators at bottom - matching reference style
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            if index == currentPage {
                                // Active indicator - elongated
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: 24, height: 8)
                            } else {
                                // Inactive indicators - small circles
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .padding(.bottom, 140)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            
            // Continue button - floating at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text(String(localized: "Continue"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.3, green: 0.6, blue: 0.95),
                                Color(red: 0.15, green: 0.4, blue: 0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.1, green: 0.3, blue: 0.7).opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Check if we need to show ATT prompt immediately on first page
            if !hasShownATTPrompt && attManager.shouldRequestPermission {
                // Small delay to let the view settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        await attManager.requestTrackingPermission()
                        hasShownATTPrompt = true
                        
                        // Track the ATT response
                        AnalyticsManager.shared.trackATTPermissionResponse(granted: attManager.isTrackingAllowed)
                    }
                }
            } else {
                // If ATT not needed, just update current status
                Task {
                    await attManager.checkCurrentStatus()
                }
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let subtitle: String
    let description: String
    let isReview: Bool
    var isVisible: Bool = true
    
    init(image: String, title: String, subtitle: String, description: String, isReview: Bool = false) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.isReview = isReview
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            // Image section
            Image(page.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 280, height: 280)
                .scaleEffect(isVisible ? 1.0 : 0.9)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
            
            Spacer()
                .frame(height: 50)
            
            // Text content
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

struct ReviewsPageView: View {
    @State private var isVisible = false
    @Environment(\.requestReview) private var requestReview
    
    private let testimonials: [PrinterTestimonial] = [
        PrinterTestimonial(
            name: "Sarah M.",
            rating: 5,
            reviewText: "This app revolutionized my home office setup! The wireless printing works flawlessly.",
            avatarColor: .blue
        ),
        PrinterTestimonial(
            name: "Mike J.",
            rating: 5,
            reviewText: "Professional-grade features in a simple app. PDF compression saves me hours every week.",
            avatarColor: .green
        ),
        PrinterTestimonial(
            name: "Lisa R.",
            rating: 5,
            reviewText: "Perfect for my small business! Fast, reliable, and the batch printing is amazing.",
            avatarColor: .orange
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
                // Title section
                VStack(spacing: 8) {
                    Text(String(localized: "Love Printer?"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
                    
                    Text(String(localized: "Join thousands of professionals who trust our solutions"))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
                }
                .padding(.bottom, 20)
                
                // Stars
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                            .scaleEffect(isVisible ? 1.0 : 0.3)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.1), value: isVisible)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .offset(y: isVisible ? 0 : 30)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isVisible)
                
                // Social proof with testimonials
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text(String(localized: "Trusted by"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        HStack(spacing: -6) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [testimonials[index].avatarColor, testimonials[index].avatarColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(String(testimonials[index].name.prefix(1)))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            }
                        }
                        
                        Text(String(localized: "5,000+ users"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.leading, 6)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .offset(y: isVisible ? 0 : 20)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isVisible)
                    
                    // Testimonials
                    VStack(spacing: 10) {
                        ForEach(Array(testimonials.enumerated()), id: \.element.id) { index, testimonial in
                            CompactTestimonialCard(testimonial: testimonial)
                                .offset(y: isVisible ? 0 : 30)
                                .opacity(isVisible ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6 + Double(index) * 0.1), value: isVisible)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Benefits
                    VStack(spacing: 8) {
                        HStack {
                            Text("🖨️")
                                .font(.system(size: 14))
                            Text(String(localized: "\"Works with any printer - no setup required\""))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                        
                        HStack {
                            Text("📄")
                                .font(.system(size: 14))
                            Text(String(localized: "\"Professional document editing and compression\""))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                        
                        HStack {
                            Text("⚡")
                                .font(.system(size: 14))
                            Text(String(localized: "\"Lightning fast printing with perfect quality\""))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
                    .offset(y: isVisible ? 0 : 30)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: isVisible)
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            // Trigger review request when testimonials page appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                requestReview()
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

struct PrinterTestimonial: Identifiable {
    let id = UUID()
    let name: String
    let rating: Int
    let reviewText: String
    let avatarColor: Color
}

struct CompactTestimonialCard: View {
    let testimonial: PrinterTestimonial
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(LinearGradient(
                    colors: [testimonial.avatarColor, testimonial.avatarColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(testimonial.name.prefix(1)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(testimonial.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    HStack(spacing: 1) {
                        ForEach(0..<testimonial.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Text(testimonial.reviewText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}