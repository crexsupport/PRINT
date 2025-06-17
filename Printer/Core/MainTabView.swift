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
    
    init() {
        // Configure tab bar appearance with white background and elevation
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        
        // Add shadow for elevation effect
        appearance.shadowImage = UIImage()
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Add layer shadow for better elevation effect
        UITabBar.appearance().layer.shadowColor = UIColor.black.cgColor
        UITabBar.appearance().layer.shadowOffset = CGSize(width: 0, height: -2)
        UITabBar.appearance().layer.shadowOpacity = 0.1
        UITabBar.appearance().layer.shadowRadius = 4
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // PANTALLA 1: Home - ICONOS SIN FILL
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            // PANTALLA 2: Photos - ICONOS SIN FILL
            PhotosTabView()
                .tabItem {
                    Image(systemName: "photo")
                    Text("Photos")
                }
                .tag(1)
            
            // PANTALLA 3: Text Notes
            TextNotesTabView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "note.text" : "note.text")
                    Text("Text Notes")
                }
                .tag(2)
            
            // PANTALLA 4: Settings - ICONOS SIN FILL
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
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
                    Button("Edit") {
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
}
