import Foundation

// MARK: - SyncCoordinator

/// Central coordinator for orchestrating all sync operations
/// Ensures correct sequencing: Chat → Logic → Memory → Beliefs
class SyncCoordinator: ObservableObject {
    @Published var isSyncInProgress = false
    @Published var lastSyncStatus: String = "Ready"
    @Published var syncHistory: [SyncEvent] = []
    
    let apiManager: APIManager
    let chatManager: ChatManager
    let logicLibrary: LogicLibrary
    let relationalMemory: RelationalMemory
    let beliefSystem: BeliefSystem
    
    // MARK: - Initialization
    
    init(
        apiManager: APIManager,
        chatManager: ChatManager,
        logicLibrary: LogicLibrary,
        relationalMemory: RelationalMemory,
        beliefSystem: BeliefSystem
    ) {
        self.apiManager = apiManager
        self.chatManager = chatManager
        self.logicLibrary = logicLibrary
        self.relationalMemory = relationalMemory
        self.beliefSystem = beliefSystem
    }
    
    // MARK: - Main Sync Workflow
    
    /// Complete workflow: Process user query through reasoning, learning, and belief updates
    /// Syncs all stages to backend with proper sequencing
    func syncCompleteInteraction(
        userQuery: String,
        sovernResponse: String,
        logicEntry: LogicEntry?,
        memoryEntry: MemoryEntry?
    ) {
        isSyncInProgress = true
        updateStatus("Starting interaction sync...")
        
        // Stage 1: Sync paradigm routing
        if let paradigmRouting = logicEntry?.paradigmRouting {
            syncParadigmStage(paradigmRouting) { [weak self] success in
                if success {
                    // Stage 2: Sync Congress debate
                    if let logicEntry = logicEntry {
                        self?.syncCongressStage(logicEntry) { success in
                            if success {
                                // Stage 3: Sync Logic entry
                                self?.syncLogicStage(logicEntry) { success in
                                    if success {
                                        // Stage 4: Sync memory & learning
                                        if let memoryEntry = memoryEntry {
                                            self?.syncMemoryStage(memoryEntry) { success in
                                                if success {
                                                    // Stage 5: Sync belief updates
                                                    self?.syncBeliefStage(from: memoryEntry) { success in
                                                        self?.completeSyncWorkflow(success)
                                                    }
                                                } else {
                                                    self?.completeSyncWorkflow(false)
                                                }
                                            }
                                        } else {
                                            self?.completeSyncWorkflow(true)
                                        }
                                    } else {
                                        self?.completeSyncWorkflow(false)
                                    }
                                }
                            } else {
                                self?.completeSyncWorkflow(false)
                            }
                        }
                    } else {
                        self?.completeSyncWorkflow(true)
                    }
                } else {
                    self?.completeSyncWorkflow(false)
                }
            }
        }
    }
    
    // MARK: - Stage-by-Stage Sync
    
    private func syncParadigmStage(_ paradigm: String, completion: @escaping (Bool) -> Void) {
        updateStatus("📋 Syncing paradigm routing...")
        
        chatManager.syncParadigmRouting(
            queryType: paradigm,
            using: apiManager
        ) { [weak self] result in
            switch result {
            case .success:
                self?.logEvent(.paradigmSync, status: .success)
                completion(true)
            case .failure:
                self?.logEvent(.paradigmSync, status: .queued)
                completion(true)  // Continue even if queued
            }
        }
    }
    
    private func syncCongressStage(_ logicEntry: LogicEntry, completion: @escaping (Bool) -> Void) {
        updateStatus("💬 Syncing Congress perspectives...")
        
        logicLibrary.syncCongressEngagement(
            entryId: logicEntry.id,
            perspectives: logicEntry.perspectives,
            using: apiManager
        ) { [weak self] result in
            switch result {
            case .success:
                self?.logEvent(.congressSync, status: .success)
                completion(true)
            case .failure:
                self?.logEvent(.congressSync, status: .queued)
                completion(true)  // Continue even if queued
            }
        }
    }
    
    private func syncLogicStage(_ logicEntry: LogicEntry, completion: @escaping (Bool) -> Void) {
        updateStatus("🧠 Syncing reasoning timeline...")
        
        logicLibrary.syncLogicEntry(
            logicEntry,
            using: apiManager
        ) { [weak self] result in
            switch result {
            case .success:
                self?.logEvent(.logicSync, status: .success)
                completion(true)
            case .failure:
                self?.logEvent(.logicSync, status: .queued)
                completion(true)  // Continue even if queued
            }
        }
    }
    
    private func syncMemoryStage(_ memoryEntry: MemoryEntry, completion: @escaping (Bool) -> Void) {
        updateStatus("📚 Syncing learning insights...")
        
        relationalMemory.syncMemoryEntry(
            memoryEntry,
            using: apiManager
        ) { [weak self] result in
            switch result {
            case .success:
                self?.logEvent(.memorySync, status: .success)
                
                // Also sync ego state
                self?.relationalMemory.syncEgoState(
                    from: memoryEntry,
                    using: self?.apiManager ?? APIManager()
                ) { egoResult in
                    switch egoResult {
                    case .success:
                        self?.logEvent(.egoStateSync, status: .success)
                        completion(true)
                    case .failure:
                        self?.logEvent(.egoStateSync, status: .queued)
                        completion(true)
                    }
                }
            case .failure:
                self?.logEvent(.memorySync, status: .queued)
                completion(true)  // Continue even if queued
            }
        }
    }
    
    private func syncBeliefStage(from memoryEntry: MemoryEntry, completion: @escaping (Bool) -> Void) {
        updateStatus("⚖️ Syncing belief updates...")
        
        // Extract belief alignments from memory entry
        let beliefAlignments = extractBeliefAlignmentsForSync(from: memoryEntry)
        
        guard !beliefAlignments.isEmpty else {
            updateStatus("✅ No belief changes to sync")
            completion(true)
            return
        }
        
        // Sync each belief alignment
        syncBeliefSequence(beliefAlignments, index: 0) { [weak self] success in
            self?.logEvent(.beliefSync, status: success ? .success : .queued)
            completion(true)
        }
    }
    
    private func syncBeliefSequence(
        _ alignments: [(stance: String, score: Double, vector: String)],
        index: Int,
        completion: @escaping (Bool) -> Void
    ) {
        guard index < alignments.count else {
            completion(true)
            return
        }
        
        let alignment = alignments[index]
        
        // Find belief by stance
        guard let belief = beliefSystem.belief(withStance: alignment.stance) else {
            // Continue with next
            syncBeliefSequence(alignments, index: index + 1, completion: completion)
            return
        }
        
        beliefSystem.syncBeliefUpdate(
            beliefId: belief.id,
            using: apiManager
        ) { [weak self] result in
            // Continue to next regardless of result
            self?.syncBeliefSequence(alignments, index: index + 1, completion: completion)
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractBeliefAlignmentsForSync(
        from memoryEntry: MemoryEntry
    ) -> [(stance: String, score: Double, vector: String)] {
        var alignments: [(stance: String, score: Double, vector: String)] = []
        
        // Analyze self-insights for belief changes
        for insight in memoryEntry.selfInsights.insights {
            if let beliefId = insight.relatedBeliefId,
               let belief = beliefSystem.belief(withId: beliefId) {
                
                let score: Double
                let vector: String
                
                switch insight.category {
                case .beliefAlignment:
                    score = 0.8
                    vector = "strengthened"
                case .growthArea:
                    score = -0.3
                    vector = "challenged"
                case .strengthIdentified:
                    score = 0.9
                    vector = "strengthened"
                default:
                    score = 0.5
                    vector = "neutral"
                }
                
                alignments.append((stance: belief.stance, score: score, vector: vector))
            }
        }
        
        return alignments
    }
    
    private func updateStatus(_ status: String) {
        DispatchQueue.main.async {
            self.lastSyncStatus = status
        }
    }
    
    private func completeSyncWorkflow(_ success: Bool) {
        DispatchQueue.main.async {
            self.isSyncInProgress = false
            self.updateStatus(success ? "✅ Sync complete" : "⚠️ Sync complete (with queued items)")
        }
    }
    
    private func logEvent(_ type: SyncEventType, status: SyncEventStatus) {
        let event = SyncEvent(
            type: type,
            status: status,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.syncHistory.append(event)
            
            // Keep only last 100 events
            if self.syncHistory.count > 100 {
                self.syncHistory.removeFirst()
            }
        }
    }
}

// MARK: - Sync Event Types

enum SyncEventType {
    case paradigmSync
    case congressSync
    case logicSync
    case memorySync
    case egoStateSync
    case beliefSync
    case coherenceSync
    case healthCheck
    
    var description: String {
        switch self {
        case .paradigmSync: return "Paradigm Routing"
        case .congressSync: return "Congress Engagement"
        case .logicSync: return "Logic Entry"
        case .memorySync: return "Memory Entry"
        case .egoStateSync: return "Ego State"
        case .beliefSync: return "Belief Update"
        case .coherenceSync: return "Coherence Score"
        case .healthCheck: return "Health Check"
        }
    }
}

enum SyncEventStatus {
    case success
    case queued
    case failed
    
    var emoji: String {
        switch self {
        case .success: return "✅"
        case .queued: return "⏳"
        case .failed: return "❌"
        }
    }
}

struct SyncEvent: Identifiable {
    let id = UUID()
    let type: SyncEventType
    let status: SyncEventStatus
    let timestamp: Date
    
    var displayText: String {
        "\(status.emoji) \(type.description) at \(timestamp.formatted(time: .shortened))"
    }
}

// MARK: - Usage in App

/*
 In your SovernApp.swift or AppCoordinator:
 
 @StateObject private var apiManager = APIManager()
 @StateObject private var syncCoordinator: SyncCoordinator
 
 init() {
     let managers = initializeManagers()
     _syncCoordinator = StateObject(wrappedValue: SyncCoordinator(
         apiManager: apiManager,
         chatManager: managers.chatManager,
         logicLibrary: managers.logicLibrary,
         relationalMemory: managers.relationalMemory,
         beliefSystem: managers.beliefSystem
     ))
 }
 
 // After generating a response:
 func processInteractionForSync(
     userQuery: String,
     classification: String,
     logicEntry: LogicEntry?,
     sovernResponse: String,
     memoryEntry: MemoryEntry?
 ) {
     syncCoordinator.syncCompleteInteraction(
         userQuery: userQuery,
         sovernResponse: sovernResponse,
         logicEntry: logicEntry,
         memoryEntry: memoryEntry
     )
 }
 
 // Monitor sync status
 @ViewBuilder
 private func syncStatusView() -> some View {
     if syncCoordinator.isSyncInProgress {
         HStack {
             ProgressView()
             Text(syncCoordinator.lastSyncStatus)
         }
         .font(.caption)
         .foregroundStyle(.secondary)
     }
 }
*/
