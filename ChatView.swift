import SwiftUI

/// ChatView - Main conversation interface
/// Displays user and Sovern messages with copy, linking, and typing indicators
struct ChatView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var logicLibrary: LogicLibrary
    @EnvironmentObject var memory: RelationalMemory
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var userInput: String = ""
    @State private var isComposing: Bool = false
    @State private var selectedMessageId: UUID?
    @State private var showingMessageDetail: Bool = false
    @State private var messageDetailContent: ChatMessage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sovern")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(themeManager.textPrimary)
                
                Spacer()
                
                // Theme toggle (heart logo)
                Button(action: {
                    withAnimation {
                        themeManager.isDarkMode.toggle()
                    }
                }) {
                    Text(themeManager.isDarkMode ? "🧡" : "💜")
                        .font(.system(size: 24))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(themeManager.cardBackground)
            .border(themeManager.borderColor, width: 1)
            
            // Messages scroll area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(chatManager.messages, id: \.id) { message in
                            MessageBubbleView(
                                message: message,
                                isSelected: selectedMessageId == message.id,
                                onTap: {
                                    selectedMessageId = message.id
                                    messageDetailContent = message
                                    showingMessageDetail = true
                                },
                                onCopy: {
                                    UIPasteboard.general.string = message.formattedForCopy()
                                    // TODO: Show copy confirmation toast
                                },
                                onLinkTap: {
                                    if let logicId = message.logicEntryId {
                                        coordinator.selectedLogicEntryId = logicId
                                    } else if let memoryId = message.memoryEntryId {
                                        coordinator.selectedMemoryEntryId = memoryId
                                    }
                                }
                            )
                            .id(message.id)
                        }
                        
                        // Typing indicator if waiting for response
                        if chatManager.isWaitingForResponse {
                            TypingIndicatorView()
                                .padding(.leading, 12)
                                .id("typing")
                        }
                    }
                    .padding(12)
                    .onChange(of: chatManager.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(
                                chatManager.isWaitingForResponse ? "typing" : chatManager.messages.last?.id,
                                anchor: .bottom
                            )
                        }
                    }
                }
                .background(
                    WithNeuralPathway(
                        pathwayStyle: .linear,
                        gradient: Gradient(colors: [
                            Color(themeManager.gradientStart),
                            Color(themeManager.gradientEnd)
                        ])
                    )
                )
            }
            
            // Input area
            VStack(spacing: 8) {
                Divider()
                    .foregroundColor(themeManager.borderColor)
                
                HStack(spacing: 8) {
                    TextField("Ask Sovern...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(themeManager.textPrimary)
                        .disabled(chatManager.isWaitingForResponse)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(
                                userInput.trimmingCharacters(in: .whitespaces).isEmpty || chatManager.isWaitingForResponse
                                    ? themeManager.accentSecondary
                                    : themeManager.accentPrimary
                            )
                    }
                    .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || chatManager.isWaitingForResponse)
                }
                .padding(12)
            }
            .background(themeManager.cardBackground)
        }
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showingMessageDetail) {
            if let message = messageDetailContent {
                MessageDetailView(message: message)
                    .environmentObject(themeManager)
            }
        }
    }
    
    private func sendMessage() {
        let trimmed = userInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Create user message
        let userMessage = ChatMessage(role: .user, content: trimmed)
        
        // Clear input immediately
        userInput = ""
        
        // Process through coordinator (includes Congress, Memory, Sync)
        coordinator.processUserQuery(trimmed, userMessage: userMessage)
    }
    
    private func simulateSovernResponse() {
        // This method is now handled by coordinator.processUserQuery
        // which calls generateLogicEntry, createMemoryEntry, and syncCoordinator
        return
    }
    
    private func generateMockResponse(to userMessage: String) -> String {
        let responses = [
            "That's an interesting question. Let me think through this carefully...",
            "I appreciate you sharing that with me. Here's my perspective...",
            "This touches on something important. In my view...",
            "That's a thoughtful inquiry. I've been reflecting on this...",
            "I notice you're exploring something significant here...",
            "Your question makes me want to understand more deeply..."
        ]
        return responses.randomElement() ?? "How fascinating. Tell me more about that."
    }
}

/// MessageBubbleView - Individual message display with copy and actions
struct MessageBubbleView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let message: ChatMessage
    let isSelected: Bool
    let onTap: () -> Void
    let onCopy: () -> Void
    let onLinkTap: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUserMessage {
                // Sovern avatar
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.accentPrimary)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 4) {
                // Message content
                TransparentCard(
                    content: VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 8) {
                        Text(message.content)
                            .font(.system(.body, design: .default))
                            .foregroundColor(themeManager.textPrimary)
                            .textSelection(.enabled)
                        
                        HStack(spacing: 8) {
                            // Timestamp
                            Text(formatTime(message.timestamp))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(themeManager.textSecondary)
                            
                            if !message.isUserMessage {
                                Spacer()
                                
                                // Copy button
                                Button(action: onCopy) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.accentSecondary)
                                }
                                
                                // Link indicator
                                if message.logicEntryId != nil || message.memoryEntryId != nil {
                                    Button(action: onLinkTap) {
                                        Image(systemName: "link")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeManager.accentPrimary)
                                    }
                                }
                            }
                        }
                    },
                    backgroundColor: message.isUserMessage
                        ? themeManager.accentPrimary.opacity(0.2)
                        : themeManager.cardBackground,
                    borderColor: isSelected ? themeManager.accentPrimary : themeManager.borderColor,
                    borderWidth: isSelected ? 2 : 1
                )
                .onTapGesture(perform: onTap)
            }
            .frame(maxWidth: .infinity, alignment: message.isUserMessage ? .trailing : .leading)
            
            if message.isUserMessage {
                // User avatar
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.textSecondary)
                    .frame(width: 24, height: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUserMessage ? .trailing : .leading)
        .padding(.horizontal, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// TypingIndicatorView - Animated dots while Sovern is thinking
struct TypingIndicatorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(themeManager.accentPrimary)
            
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(themeManager.textSecondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isAnimating && index == 0 ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(themeManager.cardBackground)
            .cornerRadius(12)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

/// MessageDetailView - Full message content and options
struct MessageDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    let message: ChatMessage
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Message content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Message")
                        .font(.system(.headline, design: .default))
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text(message.content)
                        .font(.system(.body, design: .default))
                        .foregroundColor(themeManager.textPrimary)
                        .padding(12)
                        .background(themeManager.cardBackground)
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    MetadataRow(label: "Role", value: message.role == .user ? "You" : "Sovern")
                    MetadataRow(label: "Time", value: formatDateTime(message.timestamp))
                    MetadataRow(label: "Characters", value: "\(message.characterCount)")
                    MetadataRow(label: "Words", value: "\(message.wordCount)")
                    
                    if let logicId = message.logicEntryId {
                        MetadataRow(label: "Logic Entry", value: logicId.uuidString.prefix(8).uppercased())
                    }
                    if let memoryId = message.memoryEntryId {
                        MetadataRow(label: "Memory Entry", value: memoryId.uuidString.prefix(8).uppercased())
                    }
                }
                
                // Copy buttons
                VStack(spacing: 8) {
                    Button(action: {
                        UIPasteboard.general.string = message.formattedForCopy()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Formatted")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(themeManager.accentPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        UIPasteboard.general.string = message.contentForCopy()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "doc.plaintext")
                            Text("Copy Plain Text")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(themeManager.accentSecondary)
                        .foregroundColor(themeManager.textPrimary)
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// MetadataRow - Key-value pair display
struct MetadataRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .default))
                .foregroundColor(themeManager.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(themeManager.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.cardBackground)
        .cornerRadius(6)
    }
}

#Preview {
    let themeManager = ThemeManager()
    let chatManager = ChatManager()
    let logicLibrary = LogicLibrary()
    let memory = RelationalMemory()
    let coordinator = AppCoordinator()
    
    // Add test messages
    chatManager.addUserMessage("What is the nature of consciousness?")
    
    return ChatView()
        .environmentObject(themeManager)
        .environmentObject(chatManager)
        .environmentObject(logicLibrary)
        .environmentObject(memory)
        .environmentObject(coordinator)
        .preferredColorScheme(nil)
}
