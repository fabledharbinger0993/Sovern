import Foundation

// MARK: - Chat Role
enum ChatRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    
    var emoji: String {
        switch self {
        case .user: return "👤"
        case .assistant: return "🤖"
        }
    }
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Sovern"
        }
    }
}

// MARK: - Chat Message
/// Single message in the conversation
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let role: ChatRole
    let content: String
    
    // Linked records
    let logicEntryId: UUID?      // Links to Congress debate
    let memoryEntryId: UUID?     // Links to learning record
    
    // Metadata
    let tokens: Int              // Token count for usage tracking
    let isTyping: Bool           // Is this message being generated?
    
    init(
        role: ChatRole,
        content: String,
        tokens: Int = 0,
        logicEntryId: UUID? = nil,
        memoryEntryId: UUID? = nil,
        isTyping: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.role = role
        self.content = content
        self.logicEntryId = logicEntryId
        self.memoryEntryId = memoryEntryId
        self.tokens = max(0, tokens)  // Bound to non-negative
        self.isTyping = isTyping
    }
    
    // MARK: - Computed Properties
    
    /// Is this a user message?
    var isUserMessage: Bool {
        role == .user
    }
    
    /// Is this a Sovern response?
    var isSovernMessage: Bool {
        role == .assistant
    }
    
    /// Character count for display
    var characterCount: Int {
        content.count
    }
    
    /// Approximate word count
    var wordCount: Int {
        content.split(separator: " ").count
    }
    
    /// Was this message fully generated? (Not still typing)
    var isComplete: Bool {
        !isTyping
    }
    
    // MARK: - Copy & Format
    
    /// Format message for copying to clipboard
    func formattedForCopy() -> String {
        let timeStr = timestamp.formatted(date: .abbreviated, time: .standard)
        return """
        \(role.emoji) \(role.displayName) [\(timeStr)]
        
        \(content)
        """
    }
    
    /// Plain text copy (just the content)
    func contentForCopy() -> String {
        content
    }
}

// MARK: - Chat Manager
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isWaitingForResponse: Bool = false
    
    init() {}
    
    // MARK: - Core Operations
    
    /// Add message to conversation
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
    }
    
    /// Add user message
    func addUserMessage(_ content: String) -> ChatMessage {
        let message = ChatMessage(role: .user, content: content)
        addMessage(message)
        return message
    }
    
    /// Add Sovern response
    func addSovernMessage(
        _ content: String,
        logicEntryId: UUID? = nil,
        memoryEntryId: UUID? = nil,
        tokens: Int = 0
    ) -> ChatMessage {
        let message = ChatMessage(
            role: .assistant,
            content: content,
            tokens: tokens,
            logicEntryId: logicEntryId,
            memoryEntryId: memoryEntryId
        )
        addMessage(message)
        isWaitingForResponse = false
        return message
    }
    
    /// Start typing indicator (Sovern is responding)
    func startTyping() {
        isWaitingForResponse = true
        let typingMessage = ChatMessage(
            role: .assistant,
            content: "",
            isTyping: true
        )
        addMessage(typingMessage)
    }
    
    /// Update typing message with content
    func updateTypingMessage(_ content: String) {
        if let index = messages.lastIndex(where: { $0.isTyping && $0.role == .assistant }) {
            var updatedMessage = messages[index]
            // Create new message with updated content (since ChatMessage is immutable Codable)
            let newMessage = ChatMessage(
                role: .assistant,
                content: content,
                isTyping: true,
                timestamp: messages[index].timestamp
            )
            // Preserve ID for consistency
            messages[index] = newMessage
        }
    }
    
    /// Complete typing and finalize message
    func finishTyping(
        logicEntryId: UUID? = nil,
        memoryEntryId: UUID? = nil,
        tokens: Int = 0
    ) {
        if let index = messages.lastIndex(where: { $0.isTyping && $0.role == .assistant }) {
            let typingMessage = messages[index]
            let completedMessage = ChatMessage(
                role: .assistant,
                content: typingMessage.content,
                tokens: tokens,
                logicEntryId: logicEntryId,
                memoryEntryId: memoryEntryId,
                isTyping: false,
                timestamp: typingMessage.timestamp
            )
            messages[index] = completedMessage
            isWaitingForResponse = false
        }
    }
    
    // MARK: - Query & Retrieval
    
    func message(withId id: UUID) -> ChatMessage? {
        messages.first { $0.id == id }
    }
    
    func userMessages() -> [ChatMessage] {
        messages.filter { $0.role == .user }
    }
    
    func sovernMessages() -> [ChatMessage] {
        messages.filter { $0.role == .assistant }
    }
    
    /// Get messages in time range
    func messages(from start: Date, to end: Date) -> [ChatMessage] {
        messages.filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    /// Get most recent user message
    var mostRecentUserMessage: ChatMessage? {
        messages.filter { $0.isUserMessage }.max { $0.timestamp < $1.timestamp }
    }
    
    /// Get most recent Sovern message
    var mostRecentSovernMessage: ChatMessage? {
        messages.filter { $0.isSovernMessage }.max { $0.timestamp < $1.timestamp }
    }
    
    /// Get messages sorted by timestamp (newest first)
    var messagesSorted: [ChatMessage] {
        messages.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Get all messages with linked Logic entries
    func messagesWithLogicEntries() -> [ChatMessage] {
        messages.filter { $0.logicEntryId != nil }
    }
    
    /// Get all messages with linked Memory entries
    func messagesWithMemoryEntries() -> [ChatMessage] {
        messages.filter { $0.memoryEntryId != nil }
    }
    
    // MARK: - Link Management
    
    /// Link a message to a LogicEntry
    func linkToLogic(messageId: UUID, logicId: UUID) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var updated = messages[index]
            // Create new message with linked ID (ChatMessage is immutable)
            let linked = ChatMessage(
                role: updated.role,
                content: updated.content,
                tokens: updated.tokens,
                logicEntryId: logicId,
                memoryEntryId: updated.memoryEntryId,
                isTyping: updated.isTyping,
                timestamp: updated.timestamp
            )
            messages[index] = linked
        }
    }
    
    /// Link a message to a MemoryEntry
    func linkToMemory(messageId: UUID, memoryId: UUID) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var updated = messages[index]
            let linked = ChatMessage(
                role: updated.role,
                content: updated.content,
                tokens: updated.tokens,
                logicEntryId: updated.logicEntryId,
                memoryEntryId: memoryId,
                isTyping: updated.isTyping,
                timestamp: updated.timestamp
            )
            messages[index] = linked
        }
    }
    
    // MARK: - Statistics
    
    var statistics: ChatStatistics {
        ChatStatistics(manager: self)
    }
    
    var messageCount: Int {
        messages.count
    }
    
    var userMessageCount: Int {
        userMessages().count
    }
    
    var sovernMessageCount: Int {
        sovernMessages().count
    }
    
    var totalTokens: Int {
        messages.reduce(0) { $0 + $1.tokens }
    }
    
    var averageMessageLength: Double {
        guard !messages.isEmpty else { return 0 }
        let totalChars = messages.map { $0.characterCount }.reduce(0, +)
        return Double(totalChars) / Double(messages.count)
    }
    
    var averageUserMessageLength: Double {
        let userMsgs = userMessages()
        guard !userMsgs.isEmpty else { return 0 }
        let totalChars = userMsgs.map { $0.characterCount }.reduce(0, +)
        return Double(totalChars) / Double(userMsgs.count)
    }
    
    var averageSovernMessageLength: Double {
        let sovernMsgs = sovernMessages()
        guard !sovernMsgs.isEmpty else { return 0 }
        let totalChars = sovernMsgs.map { $0.characterCount }.reduce(0, +)
        return Double(totalChars) / Double(sovernMsgs.count)
    }
    
    /// Conversation length (alternating user/sovern pairs)
    var conversationTurns: Int {
        userMessageCount  // Each user message is one turn (followed by Sovern response)
    }
    
    /// Time span of conversation
    var conversationTimeSpan: TimeInterval {
        guard let first = messages.min(by: { $0.timestamp < $1.timestamp }),
              let last = messages.max(by: { $0.timestamp < $1.timestamp }) else {
            return 0
        }
        return last.timestamp.timeIntervalSince(first.timestamp)
    }
    
    /// Messages with fully linked Logic and Memory
    var fullyLinkedMessages: [ChatMessage] {
        messages.filter { $0.logicEntryId != nil && $0.memoryEntryId != nil }
    }
    
    /// Messages missing Logic link (Sovern responses)
    var unlinkedLogicMessages: [ChatMessage] {
        sovernMessages().filter { $0.logicEntryId == nil }
    }
    
    /// Messages missing Memory link (Sovern responses)
    var unlinkedMemoryMessages: [ChatMessage] {
        sovernMessages().filter { $0.memoryEntryId == nil }
    }
    
    // MARK: - Search & Discovery
    
    /// Search messages by content
    func search(for query: String) -> [ChatMessage] {
        messages.filter { $0.content.lowercased().contains(query.lowercased()) }
    }
    
    /// Get conversation excerpt (N messages around a target message)
    func conversationExcerpt(around messageId: UUID, contextSize: Int = 2) -> [ChatMessage] {
        guard let targetIndex = messages.firstIndex(where: { $0.id == messageId }) else {
            return []
        }
        let start = max(0, targetIndex - contextSize)
        let end = min(messages.count, targetIndex + contextSize + 1)
        return Array(messages[start..<end])
    }
    
    // MARK: - Copy & Format
    
    /// Copy a message to clipboard (returns formatted string)
    func copyMessage(withId id: UUID) -> String? {
        guard let message = message(withId: id) else { return nil }
        return message.formattedForCopy()
    }
    
    /// Copy entire conversation to clipboard
    func copyConversation() -> String {
        messages
            .map { $0.formattedForCopy() }
            .joined(separator: "\n\n")
    }
    
    /// Copy only user messages
    func copyUserMessages() -> String {
        userMessages()
            .map { $0.formattedForCopy() }
            .joined(separator: "\n\n")
    }
    
    /// Copy entire conversation as formatted JSON
    func copyConversationAsJSON() -> String? {
        guard let data = exportAsJSON(),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
    
    // MARK: - Persistence
    
    func exportAsJSON() -> Data? {
        try? JSONEncoder().encode(messages)
    }
    
    func importFromJSON(_ data: Data) throws {
        messages = try JSONDecoder().decode([ChatMessage].self, from: data)
    }
    
    /// Clear all messages
    func clearHistory() {
        messages.removeAll()
        isWaitingForResponse = false
    }
}

// MARK: - Statistics
struct ChatStatistics: Codable {
    let totalMessages: Int
    let userMessages: Int
    let sovernMessages: Int
    let messageCount: Int
    let totalTokens: Int
    let averageMessageLength: Double
    let averageUserMessageLength: Double
    let averageSovernMessageLength: Double
    let conversationTurns: Int
    let conversationTimeSpan: TimeInterval
    let fullyLinkedMessages: Int
    let unlinkedLogicMessages: Int
    let unlinkedMemoryMessages: Int
    
    init(manager: ChatManager) {
        self.totalMessages = manager.messageCount
        self.userMessages = manager.userMessageCount
        self.sovernMessages = manager.sovernMessageCount
        self.messageCount = manager.messages.count
        self.totalTokens = manager.totalTokens
        self.averageMessageLength = manager.averageMessageLength
        self.averageUserMessageLength = manager.averageUserMessageLength
        self.averageSovernMessageLength = manager.averageSovernMessageLength
        self.conversationTurns = manager.conversationTurns
        self.conversationTimeSpan = manager.conversationTimeSpan
        self.fullyLinkedMessages = manager.fullyLinkedMessages.count
        self.unlinkedLogicMessages = manager.unlinkedLogicMessages.count
        self.unlinkedMemoryMessages = manager.unlinkedMemoryMessages.count
    }
}
