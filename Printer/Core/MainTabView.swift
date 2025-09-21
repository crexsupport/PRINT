//
//  MainTabView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var scannerManager: ScannerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var paywallManager: PaywallManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido principal
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    PrintablesTabView()
                case 2:
                    LabelsTabView()
                case 3:
                    SettingsView()
                default:
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 50) // Reducido aún más de 60 a 50
            
            // Custom Bottom Navigation Bar
            CustomBottomNavBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $paywallManager.shouldShowPaywall) {
            PaywallView(onDismiss: {
                paywallManager.shouldShowPaywall = false
            })
            .environmentObject(subscriptionManager)
        }
    }
}

struct CustomBottomNavBar: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        (icon: "house", title: String(localized: "Home")),
        (icon: "rectangle.grid.3x2", title: String(localized: "Printables")),
        (icon: "tag", title: String(localized: "Labels")),
        (icon: "gearshape", title: String(localized: "Settings"))
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Línea separadora como el tab bar nativo
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.33)
            
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    let tab = tabs[index]
                    let isSelected = selectedTab == index
                    
                    Button(action: {
                        selectedTab = index
                    }) {
                        VStack(spacing: 1) {
                            // Icono
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(isSelected ? .accentColor : Color(.systemGray))
                            
                            // Texto
                            Text(tab.title)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(isSelected ? .accentColor : Color(.systemGray))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .background(
                Color(.systemBackground)
                    .background(.regularMaterial, in: Rectangle()) // Efecto blur nativo
            )
        }
        .background(Color(.systemBackground))
        .frame(maxWidth: .infinity)
        .edgesIgnoringSafeArea(.bottom)
    }
}

// Wrapper para Printables sin header
struct PrintablesTabView: View {
    var body: some View {
        PrintablesView(showHeader: false)
    }
}

// Wrapper para Labels sin header  
struct LabelsTabView: View {
    var body: some View {
        LabelCreationView(showHeader: false)
    }
}

// Wrapper para Photos sin botón back
struct PhotosTabView: View {
    var body: some View {
        PhotoPrintView(showBackButton: false)
    }
}

// Wrapper para Text Notes sin botón back
struct TextNotesTabView: View {
    var body: some View {
        NavigationView {
            TextNotesMainView()
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Vista principal de Text Notes para el tab
struct TextNotesMainView: View {
    @StateObject private var viewModel = TextNotesViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header simple - SOLO cuando está en input
            if viewModel.currentStep == .input {
                HStack {
                    Text("Text Notes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(Color(.systemGroupedBackground))
            } else if viewModel.currentStep == .preview {
                // Header para preview
                HStack {
                    Button(action: {
                        viewModel.returnToInput()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Edit")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("Print Preview")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button(String(localized: "Edit")) {
                        // Empty action
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
            }
            
            // Contenido principal
            if viewModel.currentStep == .input {
                TextInputView(viewModel: viewModel)
            } else if viewModel.currentStep == .preview {
                TextPreviewView(viewModel: viewModel)
            } else {
                // Vista inicial para empezar a escribir
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "note.text")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.6))
                    
                    VStack(spacing: 12) {
                        Text("Create Text Notes")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Write or paste text to create printable notes")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        viewModel.currentStep = .input
                    }) {
                        Text("Start Writing")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    MainTabView()
        .environmentObject(ScannerManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PaywallManager())
}