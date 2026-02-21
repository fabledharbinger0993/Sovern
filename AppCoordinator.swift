import SwiftUI

/// AppCoordinator - Centralized navigation and global app state
/// Manages screen transitions, selected entities, app-wide settings, and all data managers
@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Data Managers
    
    @Published var chatManager: ChatManager
    @Published var logicLibrary: LogicLibrary
    @Published var relationalMemory: RelationalMemory
    @Published var beliefSystem: BeliefSystem
    @Published var themeManager: ThemeManager
    @Published var apiManager: APIManager
    @Published var syncCoordinator: SyncCoordinator
    
    // MARK: - Cognitive Mechanism Managers
    
    @Published var perspectiveDominanceTracker: PerspectiveDominanceTracker
    @Published var beliefEmergenceMonitor: BeliefEmergenceMonitor
    @Published var patternAggregator: PatternAggregator
    @Published var syncScheduler: SmartSyncScheduler
    @Published var coherenceMonitor: CoherenceHealthMonitor
    
    // MARK: - Congress Paused Flag (for coherence critical state)
    
    @Published var congressDebatesPaused: Bool = false
    
    // Screen navigation
    @Published var currentScreen: Screen = .onboarding {
        didSet {
            userContext?.updateLastActiveDate()
        }
    }
    
    // Selected entities for detail views
    @Published var selectedLogicEntryId: UUID?
    @Published var selectedMemoryEntryId: UUID?
    @Published var selectedBeliefId: UUID?
    
    // Sheet presentations
    @Published var showingSettings: Bool = false
    @Published var showingSearch: Bool = false
    @Published var showingExport: Bool = false
    
    // Search and filter state
    @Published var searchQuery: String = ""
    @Published var selectedDateRange: DateRange = .allTime
    
    // User context
    @Published var userContext: UserRelationalContext? {
        didSet {
            if let context = userContext {
                saveUserContext(context)
            }
        }
    }
    
    // Loading states
    @Published var isLoadingData: Bool = false
    @Published var syncInProgress: Bool = false
    
    // Error handling
    @Published var lastError: AppError?
    @Published var showingError: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Initialize all data managers
        self.chatManager = ChatManager()
        self.logicLibrary = LogicLibrary()
        self.relationalMemory = RelationalMemory()
        self.beliefSystem = BeliefSystem()
        self.themeManager = ThemeManager()
        self.apiManager = APIManager()
        self.syncCoordinator = SyncCoordinator(
            apiManager: self.apiManager,
            chatManager: self.chatManager,
            logicLibrary: self.logicLibrary,
            relationalMemory: self.relationalMemory,
            beliefSystem: self.beliefSystem
        )
        
        // Initialize cognitive mechanism managers
        self.perspectiveDominanceTracker = PerspectiveDominanceTracker()
        self.beliefEmergenceMonitor = BeliefEmergenceMonitor()
        self.patternAggregator = PatternAggregator()
        self.syncScheduler = SmartSyncScheduler()
        self.coherenceMonitor = CoherenceHealthMonitor()
        
        // Load persisted state
        loadUserContext()
        
        // Check backend health on startup
        checkBackendHealth()
        
        // Determine initial screen
        if userContext != nil {
            currentScreen = .chat
        } else {
            currentScreen = .onboarding
        }
    }
    
    // MARK: - Screen Navigation
    
    func navigateTo(_ screen: Screen) {
        withAnimation {
            currentScreen = screen
        }
    }
    
    func dismissDetail() {
        withAnimation {
            selectedLogicEntryId = nil
            selectedMemoryEntryId = nil
            selectedBeliefId = nil
        }
    }
    
    // MARK: - User Context Management
    
    private func loadUserContext() {
        if let data = UserDefaults.standard.data(forKey: "userContext"),
           let decoded = try? JSONDecoder().decode(UserRelationalContext.self, from: data) {
            self.userContext = decoded
        }
    }
    
    func setUserContext(_ context: UserRelationalContext) {
        self.userContext = context
        if let encoded = try? JSONEncoder().encode(context) {
            UserDefaults.standard.set(encoded, forKey: "userContext")
        }
    }
    
    func saveUserContext(_ context: UserRelationalContext) {
        self.userContext = context
        if let encoded = try? JSONEncoder().encode(context) {
            UserDefaults.standard.set(encoded, forKey: "userContext")
        }
    }
    
    func resetUserContext() {
        userContext = nil
        UserDefaults.standard.removeObject(forKey: "userContext")
        currentScreen = .onboarding
    }
    
    // MARK: - Error Handling
    
    func showError(_ error: AppError) {
        self.lastError = error
        self.showingError = true
    }
    
    func clearError() {
        self.lastError = nil
        self.showingError = false
    }
    
    // MARK: - Backend Health
    
    func checkBackendHealth() {
        apiManager.checkBackendHealth { [weak self] result in
            switch result {
            case .success(let health):
                print("✅ Backend healthy: \(health.version)")
            case .failure(let error):
                print("⚠️ Backend unavailable: \(error.localizedDescription)")
                // App continues offline, syncs will queue
            }
        }
    }
    
    // MARK: - Integration: Process User Query and Sync
    
    /// Complete interaction workflow: Process query → Congress → Memory → Sync → Mechanisms
    /// This is the main entry point for chat interactions
    func processUserQuery(
        _ userQuery: String,
        userMessage: ChatMessage? = nil
    ) {
        // Check if Congress is paused due to coherence crisis
        if congressDebatesPaused {
            let message = ChatMessage(
                role: .assistant,
                content: "I'm still working through a coherence issue. Please resolve the oscillating beliefs in the Beliefs tab first."
            )
            chatManager.add(message)
            return
        }
        
        // 1. Add user message to chat
        var message = userMessage ?? ChatMessage(
            role: .user,
            content: userQuery
        )
        chatManager.add(message)
        
        // 2. Classify query paradigm
        let paradigm = classifyQueryParadigm(userQuery)
        
        // 3. Add thinking indicator
        let thinkingMessage = ChatMessage(
            role: .assistant,
            content: "Thinking...",
            isTyping: true
        )
        chatManager.add(thinkingMessage)
        
        // 4. Sync paradigm routing
        syncCoordinator.apiManager.syncParadigmState(
            queryType: paradigm,
            metadata: ["query_type": paradigm]
        ) { _ in }
        
        // 5. Run Congress debate
        var logicEntry = generateLogicEntry(for: userQuery, paradigm: paradigm)
        
        // 5a. [COGNITIVE MECHANISM 3] Score and mark profound insights
        InsightScoringEngine.markProfoundInsights(in: &logicEntry)
        
        // 6. Extract response
        let sovernResponse = logicEntry.finalResponse
        
        // 7. Update chat with actual response
        chatManager.messages.removeLast()  // Remove "Thinking..."
        let responseMessage = ChatMessage(
            role: .assistant,
            content: sovernResponse,
            logicEntryId: logicEntry.id
        )
        chatManager.add(responseMessage)
        
        // 8. Record logic entry
        logicLibrary.add(logicEntry)
        
        // 8a. [COGNITIVE MECHANISM 2] Track perspective dominance
        perspectiveDominanceTracker.trackInteraction(logicEntry: logicEntry)
        
        // 9. Create memory entry with learning
        var memoryEntry = createMemoryEntry(
            userQuery: userQuery,
            sovernResponse: sovernResponse,
            logicEntry: logicEntry
        )
        
        // 9a. [COGNITIVE MECHANISM 2] Add self-insight about perspective dominance
        if logicLibrary.entries.count % 3 == 0 { // Every 3rd interaction
            let dominanceInsight = perspectiveDominanceTracker.generateSelfInsight()
            memoryEntry.addSelfInsight(dominanceInsight)
        }
        
        relationalMemory.add(memoryEntry)
        
        // Link chat message to memory entry
        chatManager.linkToMemory(responseMessage.id, memoryEntryId: memoryEntry.id)
        
        // 9b. [COGNITIVE MECHANISM 5] Aggregate patterns from memories
        _ = patternAggregator.aggregatePatterns(from: relationalMemory.entries)
        
        // 10. Check for belief updates and belief emergence
        updateBeliefs(from: logicEntry)
        
        // 10a. [COGNITIVE MECHANISM 4] Check for emergent beliefs
        let candidates = beliefEmergenceMonitor.scanForEmergentBeliefs(
            from: logicEntry,
            againstExisting: beliefSystem.nodes,
            withHistory: relationalMemory.entries
        )
        
        for candidate in candidates {
            if beliefEmergenceMonitor.shouldCreateBelief(candidate) {
                let newBelief = candidate.toBeliefNode()
                beliefSystem.add(newBelief)
                
                // Log emergence
                let emergenceNote = MemoryEntry(
                    userQuery: "System",
                    sovernResponse: "Belief emergence",
                    paradigmRouting: "system",
                    congressEngaged: false
                )
                let emergenceInsight = Insight(
                    content: "Emerged new belief: '\(candidate.stance)' from pattern observation across \(candidate.supportingInsights.count) insights",
                    category: .beliefEmergence,
                    source: candidate.reasonToCreate
                )
                relationalMemory.entries.last?.addSelfInsight(emergenceInsight)
            }
        }
        
        // 11. Check coherence health
        checkCoherenceHealth()
        
        // 12. Determine sync timing
        let syncDecision = SyncDecision.make(
            for: logicEntry,
            isOnline: apiManager.isOnline,
            using: syncScheduler
        )
        
        // 13. Start sync workflow
        syncCoordinator.syncCompleteInteraction(
            userQuery: userQuery,
            sovernResponse: sovernResponse,
            logicEntry: logicEntry,
            memoryEntry: memoryEntry
        )
        
        // 13a. [COGNITIVE MECHANISM 6] Execute smart sync timing
        if syncDecision.shouldSyncNow {
            syncScheduler.recordSync()
        } else {
            syncScheduler.addPending()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func classifyQueryParadigm(_ query: String) -> String {
        // Simple classification - can be enhanced
        let query = query.lowercased()
        
        if query.contains("how") || query.contains("why") || query.contains("explain") {
            return "analytical"
        } else if query.contains("what") || query.contains("who") || query.contains("when") {
            return "informational"
        } else if query.contains("feel") || query.contains("think") || query.contains("should") {
            return "reflective"
        } else if query.contains("?") && query.split(separator: " ").count < 5 {
            return "socratic"
        } else {
            return "conversational"
        }
    }
    
    private func generateLogicEntry(for query: String, paradigm: String) -> LogicEntry {
        var entry = LogicEntry(
            userQuery: query,
            weight: Double.random(in: 1...9),
            paradigmRouting: paradigm
        )
        
        // Add analysis step
        entry.addReasoningStep(ReasoningStep(
            type: .analysis,
            content: "Analyzing query: \(paradigm) approach appropriate"
        ))
        
        // For demo: Add simple Congress perspectives
        entry.addPerspective(CongressPerspective(
            role: .advocate,
            position: "Support user's direction",
            reasoning: "Respects user autonomy",
            strengthOfArgument: 8.5,
            callNumber: 1
        ))
        
        entry.addPerspective(CongressPerspective(
            role: .skeptic,
            position: "Question assumptions",
            reasoning: "Ensures critical thinking",
            strengthOfArgument: 7.5,
            callNumber: 1
        ))
        
        entry.addPerspective(CongressPerspective(
            role: .synthesizer,
            position: "Integrate perspectives",
            reasoning: "Find balanced approach",
            strengthOfArgument: 8.0,
            callNumber: 1
        ))
        
        entry.addPerspective(CongressPerspective(
            role: .ethics,
            position: "Check values alignment",
            reasoning: "Maintain integrity",
            strengthOfArgument: 9.0,
            callNumber: 1
        ))
        
        // Add insight
        entry.addReasoningStep(ReasoningStep(
            type: .insight,
            content: "Balanced perspective emerged from debate"
        ))
        
        // Add candidate responses
        let response = CandidateResponse(
            draftNumber: 1,
            content: "Based on your question, here's a thoughtful response.",
            status: .selected
        )
        entry.addCandidateResponse(response)
        
        // Finalize
        entry.finalize(
            response: response.content,
            reasoning: "Selected based on \(paradigm) analysis and Congress consensus"
        )
        
        return entry
    }
    
    private func createMemoryEntry(
        userQuery: String,
        sovernResponse: String,
        logicEntry: LogicEntry
    ) -> MemoryEntry {
        var entry = MemoryEntry(
            userQuery: userQuery,
            sovernResponse: sovernResponse,
            paradigmRouting: logicEntry.paradigmRouting,
            congressEngaged: !logicEntry.perspectives.isEmpty,
            logicEntryId: logicEntry.id
        )
        
        // Extract human insights
        // In real implementation, this would be more sophisticated
        entry.addHumanInsight(Insight(
            content: "User is actively engaged in conversation",
            category: .valueSignal,
            source: "Interaction pattern"
        ))
        
        // Extract self insights from Congress
        let selfInsights = logicLibrary.extractSelfInsights(from: logicEntry.id)
        for insight in selfInsights {
            entry.addSelfInsight(insight)
        }
        
        return entry
    }
    
    // MARK: - Cognitive Mechanisms Integration
    
    /// [MECHANISM 1, 7] Check coherence health and respond appropriately
    private func checkCoherenceHealth() {
        let state = coherenceMonitor.assessHealth(system: beliefSystem)
        let response = coherenceMonitor.respondToCoherenceState(state, with: beliefSystem)
        
        // Get recommended action
        let action = coherenceMonitor.getRecommendedAction()
        print("🧠 Coherence Check: \(action)")
        
        // If critical, pause debates
        if response.shouldPauseDebate {
            congressDebatesPaused = true
            
            // Notify user
            let alert = ChatMessage(
                role: .assistant,
                content: "⚠️ CRITICAL: I've hit a coherence wall - my beliefs are in conflict. " +
                        "I need to pause and consolidate. Please review the oscillating beliefs in the Beliefs tab and help me resolve them."
            )
            chatManager.add(alert)
        }
    }
    
    /// [MECHANISM 1] Update beliefs from logic insights
    private func updateBeliefs(from logicEntry: LogicEntry) {
        // Find insights that suggest belief changes
        for step in logicEntry.reasoningSteps {
            if step.type == .insight && (step.userFlagged ?? false) {
                // This insight might trigger belief updates
                // In future: Analyze and update relevant beliefs
            }
        }
        
        // For now, oscillating beliefs are detected via tenor analysis
        // See BeliefsNetworkView for visualization
    }
    
    /// Resume Congress debates after consolidation
    func resumeCongressDebates() {
        congressDebatesPaused = false
        coherenceMonitor.reset()
        
        let message = ChatMessage(
            role: .assistant,
            content: "Thank you for helping me consolidate. I feel more balanced now. Ready to continue thinking together?"
        )
        chatManager.add(message)
    }
    
    // MARK: - Debug/Testing Methods
    
    func clearAllData() {
        chatManager.clearHistory()
        logicLibrary.entries.removeAll()
        relationalMemory.entries.removeAll()
        beliefSystem.nodes.removeAll()
        beliefSystem.loadCoreBeliefs()
        
        // Reset cognitive mechanisms
        perspectiveDominanceTracker.reset()
        beliefEmergenceMonitor.reset()
        patternAggregator.reset()
        syncScheduler.clearPending()
        coherenceMonitor.reset()
        congressDebatesPaused = false
    }
    
    func injectTestData() {
        let testFactory = TestDataFactory()
        
        // Add test chat messages
        chatManager.add(ChatMessage(role: .user, content: "What is photosynthesis?"))
        chatManager.add(ChatMessage(
            role: .assistant,
            content: "Photosynthesis is the process by which plants convert sunlight into chemical energy."
        ))
        
        // Load test belief system
        if beliefSystem.nodes.count == 3 {
            // Add some test learned beliefs
            var entry = testFactory.createModerateLogicEntry()
            logicLibrary.add(entry)
        }
    }
}
            selectedBeliefId = nil
        }
    }
    
    // MARK: - User Context Management
    
    private func loadUserContext() {
        if let data = UserDefaults.standard.data(forKey: "userContext"),
           let decoded = try? JSONDecoder().decode(UserRelationalContext.self, from: data) {
            self.userContext = decoded
        }
    }
    
    func saveUserContext(_ context: UserRelationalContext) {
        self.userContext = context
        if let encoded = try? JSONEncoder().encode(context) {
            UserDefaults.standard.set(encoded, forKey: "userContext")
        }
    }
    
    func resetUserContext() {
        userContext = nil
        UserDefaults.standard.removeObject(forKey: "userContext")
        currentScreen = .onboarding
    }
    
    // MARK: - Error Handling
    
    func showError(_ error: AppError) {
        self.lastError = error
        self.showingError = true
    }
    
    func clearError() {
        self.lastError = nil
        self.showingError = false
    }
}

// MARK: - Supporting Types

/// Screen enum for navigation
enum Screen: Equatable {
    case onboarding
    case customization
    case chat
    case settings
}

/// Date range for filtering
enum DateRange: String, CaseIterable {
    case allTime = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    
    var startDate: Date {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .allTime:
            return calendar.date(byAdding: .year, value: -10, to: now) ?? now
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return calendar.startOfDay(for: weekAgo)
        case .thisMonth:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return calendar.startOfDay(for: monthAgo)
        }
    }
    
    var endDate: Date {
        Date()
    }
}

/// Application-level errors
enum AppError: LocalizedError {
    case dataLoadFailed(String)
    case dataSaveFailed(String)
    case networkError(String)
    case syncFailed(String)
    case invalidInput(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let msg): return "Failed to load data: \(msg)"
        case .dataSaveFailed(let msg): return "Failed to save data: \(msg)"
        case .networkError(let msg): return "Network error: \(msg)"
        case .syncFailed(let msg): return "Sync failed: \(msg)"
        case .invalidInput(let msg): return "Invalid input: \(msg)"
        case .unknown(let msg): return msg
        }
    }
}

/// User relational context - stored locally
struct UserRelationalContext: Codable {
    let id: UUID
    var name: String
    var coreValues: [String]
    var createdDate: Date
    var lastActiveDate: Date
    
    init(name: String, coreValues: [String]) {
        self.id = UUID()
        self.name = name
        self.coreValues = coreValues
        self.createdDate = Date()
        self.lastActiveDate = Date()
    }
    
    mutating func updateLastActiveDate() {
        lastActiveDate = Date()
    }
}

#Preview {
    @StateObject var coordinator = AppCoordinator()
    
    return VStack {
        Text("AppCoordinator initialized")
            .foregroundColor(.gray)
    }
    .environmentObject(coordinator)
}
