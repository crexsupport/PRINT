//
//  DocumentCollectionView.swift
//  Printer
//
//  Created by Pol Nadal Serra on 14/6/25.
//

import SwiftUI

struct DocumentCollectionView: View {
    let images: [UIImage]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("Photo Print")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        // Share functionality
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if !images.isEmpty {
                    // Document viewer
                    VStack {
                        // Trash button
                        HStack {
                            Button(action: {
                                // Delete current document
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Circle().fill(Color.gray.opacity(0.2)))
                            }
                            .padding(.leading)
                            
                            Spacer()
                        }
                        .padding(.top)
                        
                        // Document image
                        TabView(selection: $currentPage) {
                            ForEach(0..<images.count, id: \.self) { index in
                                ZStack { 
                                    Color.white
                                    Image(uiImage: images[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(20)
                                }
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .padding()
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        
                        // Page indicator
                        HStack {
                            Button(action: {
                                if currentPage > 0 {
                                    withAnimation {
                                        currentPage -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentPage > 0 ? .primary : .gray)
                                    .padding(8)
                                    .background(Circle().fill(Color.gray.opacity(0.2)))
                            }
                            .disabled(currentPage == 0)
                            
                            Spacer()
                            
                            Text("\(currentPage + 1) / \(images.count)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.2))
                                )
                            
                            Spacer()
                            
                            Button(action: {
                                if currentPage < images.count - 1 {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentPage < images.count - 1 ? .primary : .gray)
                                    .padding(8)
                                    .background(Circle().fill(Color.gray.opacity(0.2)))
                            }
                            .disabled(currentPage >= images.count - 1)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Bottom buttons
                    HStack(spacing: 20) {
                        Button("Add") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        
                        Button("Print(\(images.count))") {
                            // Print all documents
                            onSave()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                    }
                    .padding()
                    
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No documents scanned")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Capture some documents to see them here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    DocumentCollectionView(images: []) {
        // Preview action
    }
}
