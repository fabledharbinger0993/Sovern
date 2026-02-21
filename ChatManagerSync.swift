import Foundation

// MARK: - ChatManager Sync Extension

extension ChatManager {
    
    /// Sync paradigm routing state to backend after query processing
    func syncParadigmRouting(
        queryType: String,
        metadata: [String: String]? = nil,
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        apiManager.syncParadigmState(
            queryType: queryType,
            metadata: metadata,
            completion: completion
        )
    }
    
    /// Sync a Sovern message with linked Logic entry for backend traceability
    /// This is called after a Sovern message is generated and linked to a LogicEntry
    func syncSovernMessage(
        _ message: ChatMessage,
        with logicEntry: LogicEntry?,
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        // Logic entry is synced separately by LogicLibrary
        // This just ensures the message itself is recorded with metadata
        let metadata: [String: String] = [
            "message_id": message.id.uuidString,
            "linked_logic": logicEntry?.id.uuidString ?? "none",
            "token_count": String(message.tokens),
            "is_typing": String(message.isTyping)
        ]
        
        apiManager.syncParadigmState(
            queryType: "message_sync",
            metadata: metadata,
            completion: completion
        )
    }
    
    /// Export conversation for syncing as batch (useful for debug or offline recovery)
    func exportConversationForSync() -> [[String: String]] {
        return messages.map { message in
            [
                "id": message.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: message.timestamp),
                "role": message.role.rawValue,
                "content": message.content,
                "tokens": String(message.tokens),
                "logic_entry_id": message.logicEntryId?.uuidString ?? "nil",
                "memory_entry_id": message.memoryEntryId?.uuidString ?? "nil"
            ]
        }
    }
}
