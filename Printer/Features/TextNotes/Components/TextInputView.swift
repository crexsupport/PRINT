import SwiftUI

struct TextInputView: View {
    @ObservedObject var viewModel: TextNotesViewModel
    @FocusState private var isTextEditorFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    // Safe computed properties
    private var safeKeyboardHeight: CGFloat {
        max(0, keyboardHeight.isFinite ? keyboardHeight : 0)
    }
    
    private var safeBottomPadding: CGFloat {
        return safeKeyboardHeight > 0 ? 150.0 : 40.0
    }
    
    private var safeMinHeight: CGFloat {
        return safeKeyboardHeight > 0 ? 800.0 : 700.0
    }
    
    private var safeSpacerHeight: CGFloat {
        return safeKeyboardHeight > 0 ? 50.0 : 100.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            ScrollView {
                VStack(spacing: 0) {
                    // PDF-like document for input
                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            // Typewriter placeholder animation when empty
                            if viewModel.inputText.isEmpty {
                                TypewriterPlaceholder(
                                    isVisible: !isTextEditorFocused,
                                    onComplete: {
                                        // Auto-focus when typewriter completes
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isTextEditorFocused = true
                                        }
                                    }
                                )
                                .padding(.horizontal, 30)
                                .padding(.top, 40)
                            }
                            
                            // Text editor styled like PDF content - ALWAYS present
                            TextEditor(text: $viewModel.inputText)
                                .font(.system(size: 14))
                                .focused($isTextEditorFocused)
                                .padding(.horizontal, 30)
                                .padding(.top, 40)
                                .padding(.bottom, safeBottomPadding)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .opacity(viewModel.inputText.isEmpty && !isTextEditorFocused ? 0.01 : 1.0)
                                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                                            let keyboardRect = keyboardFrame.cgRectValue
                                            let height = keyboardRect.height
                                            
                                            // Validate the height value and add better bounds checking
                                            if height.isFinite && height > 50 && height < 500 {
                                                keyboardHeight = height
                                            } else {
                                                keyboardHeight = 300.0
                                            }
                                        } else {
                                            keyboardHeight = 300.0
                                        }
                                    }
                                }
                                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        keyboardHeight = 0
                                    }
                                }
                        }
                    }
                    .background(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: safeMinHeight)
                    .cornerRadius(0)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            .padding(.horizontal, 16)
                    )
                    
                    Spacer()
                        .frame(height: safeSpacerHeight)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .scrollIndicators(.hidden)
            .animation(.easeInOut(duration: 0.3), value: safeKeyboardHeight)
            
            // Stats bar at bottom (when not typing)
            if viewModel.hasText && !isTextEditorFocused {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 20) {
                        // Characters
                        HStack(spacing: 6) {
                            Image(systemName: "textformat.alt")
                                .font(.caption)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(viewModel.characterCount)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("chars")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Words
                        HStack(spacing: 6) {
                            Image(systemName: "textformat")
                                .font(.caption)
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(viewModel.wordCount)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("words")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Pages
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(viewModel.getPageCount())")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(viewModel.getPageCount() == 1 ? "page" : "pages")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            viewModel.showPreview()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "eye")
                                    .font(.caption)
                                Text("Preview")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if isTextEditorFocused {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack {
                        Text("\(viewModel.characterCount) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if viewModel.hasText {
                            Button("Preview") {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                isTextEditorFocused = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    viewModel.showPreview()
                                }
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.blue)
                            .buttonStyle(.plain)
                        }
                        
                        Button("Done") {
                            isTextEditorFocused = false
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.blue)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
                .frame(height: 50)
            }
        }
        .onTapGesture {
            if !isTextEditorFocused {
                isTextEditorFocused = true
            }
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if !isTextEditorFocused {
                        isTextEditorFocused = true
                    }
                }
        )
    }
}

// MARK: - Faster Typewriter Animation Component
struct TypewriterPlaceholder: View {
    let isVisible: Bool
    let onComplete: () -> Void
    @State private var displayText = ""
    @State private var showCursor = true
    @State private var hasCompleted = false
    
    private let fullText = String(localized: "Start typing your document here...")
    
    var body: some View {
        HStack {
            Text(displayText + (showCursor && isVisible ? "|" : ""))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: isVisible)
            Spacer()
        }
        .onAppear {
            if isVisible && !hasCompleted {
                startTypewriterEffect()
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue && !hasCompleted {
                displayText = ""
                hasCompleted = false
                startTypewriterEffect()
            }
        }
    }
    
    private func startTypewriterEffect() {
        guard isVisible && !hasCompleted else { return }
        
        // Much faster typing - 0.04 seconds between characters
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                guard isVisible && !hasCompleted else { return }
                displayText += String(character)
                
                // Call completion when done typing
                if index == fullText.count - 1 {
                    hasCompleted = true
                    // Brief pause then trigger keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        TextInputView(viewModel: TextNotesViewModel())
    }
}
