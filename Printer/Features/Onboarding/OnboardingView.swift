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
            image: "onboarding_printer",
            title: "Professional Printing",
            subtitle: "Solutions",
            description: "Transform your mobile device into a powerful printing hub with enterprise-grade features and precision.",
            isReview: false
        ),
        OnboardingPage(
            image: "onboarding_documents",
            title: "Advanced Document",
            subtitle: "Management",
            description: "Handle complex documents with professional editing tools, batch processing, and intelligent organization.",
            isReview: false
        ),
        OnboardingPage(
            image: "onboarding_wireless",
            title: "Seamless Wireless",
            subtitle: "Integration",
            description: "Connect instantly to any printer with zero configuration. Cloud printing and network discovery included.",
            isReview: false
        ),
        OnboardingPage(
            image: "",
            title: "Love Printer?",
            subtitle: "",
            description: "Join thousands of professionals who trust our printing solutions for their daily workflow needs.",
            isReview: true
        )
    ]
    
    var body: some View {
        ZStack {
            // Premium background
            LinearGradient(
                colors: [
                    Color.white,
                    Color.blue.opacity(0.01),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if pages[currentPage].isReview {
                // Special layout for reviews page - full screen
                VStack(spacing: 0) {
                    // Progress indicators for reviews
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.15))
                                .frame(width: index == currentPage ? 10 : 6, height: index == currentPage ? 10 : 6)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    
                    // Reviews content - takes all remaining space
                    ReviewsPageView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Normal layout for other pages
                VStack(spacing: 0) {
                    // Clean progress indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.15))
                                .frame(width: index == currentPage ? 10 : 6, height: index == currentPage ? 10 : 6)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Content area
                    ZStack {
                        ForEach(0..<pages.count, id: \.self) { index in
                            if index == currentPage {
                                OnboardingPageView(page: pages[index])
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut(duration: 0.4), value: currentPage)
                }
            }
            
            // Continue button - floating for all pages
            VStack {
                Spacer()
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
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
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(
                        color: .blue.opacity(pages[currentPage].isReview ? 0.3 : 0.25),
                        radius: pages[currentPage].isReview ? 16 : 12,
                        x: 0,
                        y: pages[currentPage].isReview ? 8 : 4
                    )
                }
                .padding(.horizontal, pages[currentPage].isReview ? 40 : 32)
                .padding(.bottom, pages[currentPage].isReview ? 50 : 70)
                .animation(.easeInOut(duration: 0.4), value: currentPage)
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
            // Minimal top spacer
            Spacer().frame(height: 20)
            
            // Image section with premium styling
            VStack(spacing: 15) {
                ZStack {
                    // Subtle background circle
                    Circle()
                        .fill(Color.blue.opacity(0.03))
                        .frame(width: 220, height: 220)
                    
                    // Main image
                    Image(page.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 170, height: 170)
                        .shadow(color: .black.opacity(0.05), radius: 24, x: 0, y: 8)
                }
                .scaleEffect(isVisible ? 1.0 : 0.9)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
            }
            
            // Reduced spacer
            Spacer().frame(height: 25)
            
            // Text content with professional spacing
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(page.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
                    
                    if !page.subtitle.isEmpty {
                        Text(page.subtitle)
                            .font(.system(size: 27, weight: .light))
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .offset(y: isVisible ? 0 : 20)
                            .opacity(isVisible ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: isVisible)
                    }
                }
                
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 35)
                    .offset(y: isVisible ? 0 : 30)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isVisible)
            }
            
            // Bottom spacer - reserving space for floating button
            Spacer().frame(minHeight: 130)
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
                // Compact title section
                VStack(spacing: 8) {
                    Text("Love Printer?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
                    
                    Text("Join thousands of professionals who trust our solutions")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Compact stars
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
                .padding(.bottom, 16)
                .offset(y: isVisible ? 0 : 30)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isVisible)
                
                // Social proof with testimonials immediately visible
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Trusted by")
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
                        
                        Text("5,000+ users")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.leading, 6)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .offset(y: isVisible ? 0 : 20)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isVisible)
                    
                    // All testimonials visible immediately
                    VStack(spacing: 10) {
                        ForEach(Array(testimonials.enumerated()), id: \.element.id) { index, testimonial in
                            CompactTestimonialCard(testimonial: testimonial)
                                .offset(y: isVisible ? 0 : 30)
                                .opacity(isVisible ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6 + Double(index) * 0.1), value: isVisible)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Compact benefits
                    VStack(spacing: 8) {
                        HStack {
                            Text("🖨️")
                                .font(.system(size: 14))
                            Text("\"Works with any printer - no setup required\"")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                        
                        HStack {
                            Text("📄")
                                .font(.system(size: 14))
                            Text("\"Professional document editing and compression\"")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                        
                        HStack {
                            Text("⚡")
                                .font(.system(size: 14))
                            Text("\"Lightning fast printing with perfect quality\"")
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
                
                // Bottom spacing to avoid floating button overlap
                Spacer().frame(height: 120)
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
