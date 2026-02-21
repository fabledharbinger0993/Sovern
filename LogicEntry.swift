import Foundation

// MARK: - Congress Perspective
/// Represents one perspective in a Congress debate (Advocate, Skeptic, Synthesizer, Ethics)
struct CongressPerspective: Codable, Identifiable {
    let id: UUID
    let role: CongressRole
    let position: String          // The stance this perspective takes
    let reasoning: String         // Detailed reasoning behind the position
    let strengthOfArgument: Double // 1-10 scale for how compelling this perspective is
    let callNumber: Int           // Which of the multi-call Congress sequence (1-4 for high weight)
    let linkedBeliefIds: [UUID]   // NEW: Beliefs informing this perspective (Advocate/Skeptic leverage these)
    let timestamp: Date
    
    init(
        role: CongressRole,
        position: String,
        reasoning: String,
        strengthOfArgument: Double = 8.0,
        callNumber: Int = 1,
        linkedBeliefIds: [UUID] = [],
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.role = role
        self.position = position
        self.reasoning = reasoning
        self.strengthOfArgument = min(10, max(1, strengthOfArgument)) // Bound 1-10
        self.callNumber = callNumber
        self.linkedBeliefIds = linkedBeliefIds
        self.timestamp = timestamp
    }
    
    /// Update strength based on aligned beliefs (higher weight beliefs = stronger argument)
    func strengthenedWithBeliefs(_ beliefs: [BeliefNode]) -> Double {
        let alignedBeliefStrength = beliefs
            .filter { linkedBeliefIds.contains($0.id) }
            .map { Double($0.weight) / 10.0 }  // Normalize 1-10 to 0-1
            .reduce(0, +)
        
        if linkedBeliefIds.isEmpty {
            return strengthOfArgument
        }
        
        let averageBeliefStrength = alignedBeliefStrength / Double(linkedBeliefIds.count)
        // Blend: 60% from beliefs, 40% from base argument strength
        let strengthenedScore = (strengthOfArgument * 0.4) + (averageBeliefStrength * 10.0 * 0.6)
        return min(10, max(1, strengthenedScore))
    }
}

// MARK: - Congress Role Enum
enum CongressRole: String, Codable, CaseIterable {
    case advocate = "Advocate"
    case skeptic = "Skeptic"
    case synthesizer = "Synthesizer"
    case ethics = "Ethics"
    
    var description: String {
        switch self {
        case .advocate:
            return "Makes strongest case for position; supports user/idea"
        case .skeptic:
            return "Questions assumptions; identifies risks and pitfalls"
        case .synthesizer:
            return "Finds common ground; integrative solutions"
        case .ethics:
            return "Evaluates alignment with core values and impact"
        }
    }
    
    var emoji: String {
        switch self {
        case .advocate: return "✨"
        case .skeptic: return "⚠️"
        case .synthesizer: return "🔗"
        case .ethics: return "⚖️"
        }
    }
}

// MARK: - Reasoning Step
/// Represents a single step in real-time reasoning (analysis, concern, debate, insight, revision)
struct ReasoningStep: Codable, Identifiable {
    let id: UUID
    let type: ReasoningStepType
    let content: String           // What was discovered/analyzed
    let timestamp: Date
    
    // For revisions: track original vs. revised
    var originalReasoning: String?
    var revisionReason: String?
    
    init(
        type: ReasoningStepType,
        content: String,
        timestamp: Date = Date(),
        originalReasoning: String? = nil,
        revisionReason: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.originalReasoning = originalReasoning
        self.revisionReason = revisionReason
    }
}

enum ReasoningStepType: String, Codable, CaseIterable {
    case analysis = "analysis"
    case concern = "concern"
    case debate = "debate"
    case insight = "insight"
    case revision = "revision"
    
    var emoji: String {
        switch self {
        case .analysis: return "🔍"
        case .concern: return "⚠️"
        case .debate: return "💬"
        case .insight: return "✨"
        case .revision: return "🔄"
        }
    }
    
    var description: String {
        switch self {
        case .analysis:
            return "Initial problem decomposition"
        case .concern:
            return "Risks or tensions identified"
        case .debate:
            return "Perspectives in conversation"
        case .insight:
            return "Emergent truth discovered"
        case .revision:
            return "Original reasoning revised with new understanding"
        }
    }
}

// MARK: - Candidate Response
/// Represents an iteration in the response drafting process
struct CandidateResponse: Codable, Identifiable {
    let id: UUID
    let draftNumber: Int
    let content: String
    let status: ResponseStatus
    let rejectionReason: String?  // Why this draft was rejected (if applicable)
    let timestamp: Date
    
    init(
        draftNumber: Int,
        content: String,
        status: ResponseStatus,
        rejectionReason: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.draftNumber = draftNumber
        self.content = content
        self.status = status
        self.rejectionReason = rejectionReason
        self.timestamp = timestamp
    }
}

enum ResponseStatus: String, Codable {
    case rejected = "rejected"
    case selected = "selected"
    case considering = "considering"
    
    var emoji: String {
        switch self {
        case .rejected: return "❌"
        case .selected: return "✅"
        case .considering: return "🤔"
        }
    }
}

// MARK: - Congress Engagement Strategy
enum CongressEngagementStrategy: String, Codable {
    case direct = "direct"                    // 1-2.9: Single call with internal routing
    case singleDebate = "single_debate"       // 3-5.9: One Congress debate (all 3 perspectives)
    case multiCall = "multi_call"             // 6-9: Multi-call sequence (4 calls total)
    
    var description: String {
        switch self {
        case .direct:
            return "Direct Paradigm routing through internal Logic/Beliefs/Memory"
        case .singleDebate:
            return "Single Congress call engaging all three perspectives simultaneously"
        case .multiCall:
            return "Multi-call Congress sequence: Advocate → Skeptic → Synthesizer → Final reconciliation"
        }
    }
}

// MARK: - Complexity/Weight Category
enum ComplexityCategory: String, Codable {
    case simple = "simple"           // 1.0-2.9
    case moderate = "moderate"       // 3.0-5.9
    case complex = "complex"         // 6.0-9.0
    
    var range: ClosedRange<Double> {
        switch self {
        case .simple: return 1.0...2.9
        case .moderate: return 3.0...5.9
        case .complex: return 6.0...9.0
        }
    }
}

// MARK: - Logic Entry (Main)
/// Complete reasoning session: Congress debate, response drafting, insight extraction
struct LogicEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let userQuery: String
    
    // Weight & routing
    let weight: Double               // 1-9 scale: complexity and relational richness
    let complexityCategory: ComplexityCategory
    let paradigmRouting: String      // Strategy selected (e.g., "analytical", "empathetic", "socratic")
    
    // Congress engagement
    let engagementStrategy: CongressEngagementStrategy
    let congressCallSequence: [Int]  // Which calls were made (e.g., [1] for single, [1,2,3,4] for multi)
    var perspectivesByCall: [[CongressPerspective]] // Grouped by call number
    
    // Reasoning timeline
    var reasoningSteps: [ReasoningStep]
    
    // Response development
    var candidateResponses: [CandidateResponse]
    
    // Profound insights
    var profoundInsights: [String]  // Tagged with ✨ emoji
    
    // Final selection
    let finalResponse: String
    let finalReasoning: String       // WHY this response was selected
    
    init(
        userQuery: String,
        weight: Double,
        paradigmRouting: String,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.userQuery = userQuery
        self.weight = min(9.0, max(1.0, weight)) // Bound 1-9
        
        // Determine complexity category
        if weight < 3.0 {
            self.complexityCategory = .simple
        } else if weight < 6.0 {
            self.complexityCategory = .moderate
        } else {
            self.complexityCategory = .complex
        }
        
        self.paradigmRouting = paradigmRouting
        
        // Determine engagement strategy and call sequence
        switch self.complexityCategory {
        case .simple:
            self.engagementStrategy = .direct
            self.congressCallSequence = []
            self.perspectivesByCall = []
            
        case .moderate:
            self.engagementStrategy = .singleDebate
            self.congressCallSequence = [1]
            self.perspectivesByCall = [[] ] // One empty array for call 1
            
        case .complex:
            self.engagementStrategy = .multiCall
            self.congressCallSequence = [1, 2, 3, 4]
            self.perspectivesByCall = [[], [], [], []] // Four empty arrays for calls 1-4
        }
        
        self.reasoningSteps = []
        self.candidateResponses = []
        self.profoundInsights = []
        self.finalResponse = ""
        self.finalReasoning = ""
    }
    
    // MARK: - Mutating Methods
    
    /// Add a reasoning step to the timeline
    mutating func addReasoningStep(_ step: ReasoningStep) {
        reasoningSteps.append(step)
    }
    
    /// Add a perspective to the specified call's deliberation
    mutating func addPerspective(_ perspective: CongressPerspective) {
        let callIndex = perspective.callNumber - 1
        if callIndex >= 0 && callIndex < perspectivesByCall.count {
            perspectivesByCall[callIndex].append(perspective)
        }
    }
    
    /// Add a candidate response draft
    mutating func addCandidateResponse(_ response: CandidateResponse) {
        candidateResponses.append(response)
    }
    
    /// Add a profound insight (extracted during reasoning)
    mutating func addProfoundInsight(_ insight: String) {
        profoundInsights.append("✨ " + insight)
    }
    
    /// Set the final response and selection reasoning
    mutating func finalize(response: String, reasoning: String) {
        self.finalResponse = response
        self.finalReasoning = reasoning
    }
    
    // MARK: - Computed Properties
    
    /// All perspectives across all calls, flattened
    var allPerspectives: [CongressPerspective] {
        perspectivesByCall.flatMap { $0 }
    }
    
    /// Count of Congress calls that were made
    var congressCallCount: Int {
        congressCallSequence.count
    }
    
    /// Total number of candidate responses drafted
    var draftCount: Int {
        candidateResponses.count
    }
    
    /// Most compelling perspective (by strength)
    var mostCompellingPerspective: CongressPerspective? {
        allPerspectives.max { $0.strengthOfArgument < $1.strengthOfArgument }
    }
    
    /// Were multiple perspectives engaged? (Congress involved)
    var congressEngaged: Bool {
        !allPerspectives.isEmpty
    }
    
    /// Total reasoning steps recorded
    var reasoningStepCount: Int {
        reasoningSteps.count
    }
    
    /// Debate timeline summary
    var timeSummary: String {
        if let first = reasoningSteps.first, let last = reasoningSteps.last {
            let duration = last.timestamp.timeIntervalSince(first.timestamp)
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
        return "—"
    }
    
    /// Weight explanation for UI display
    var weightExplanation: String {
        switch complexityCategory {
        case .simple:
            return "Simple (1-2.9): Direct Paradigm answer from internal Logic/Beliefs/Memory"
        case .moderate:
            return "Moderate (3-5.9): Congress debates once with Advocate, Skeptic, Synthesizer"
        case .complex:
            return "Complex (6-9): Multi-call Congress: Advocate → Skeptic → Synthesizer → Final"
        }
    }
}

// MARK: - Logic Library (Manager)
class LogicLibrary: ObservableObject {
    @Published var entries: [LogicEntry] = []
    
    init() {}
    
    /// Add a new LogicEntry
    func add(_ entry: LogicEntry) {
        entries.append(entry)
    }
    
    /// Retrieve all entries for a user query (may be multiple deliberations on same query)
    func entries(for userQuery: String) -> [LogicEntry] {
        entries.filter { $0.userQuery == userQuery }
    }
    
    /// Get entry by ID
    func entry(withId id: UUID) -> LogicEntry? {
        entries.first { $0.id == id }
    }
    
    /// Get entries by complexity category
    func entries(in category: ComplexityCategory) -> [LogicEntry] {
        entries.filter { $0.complexityCategory == category }
    }
    
    /// Get entries by engagement strategy
    func entries(with strategy: CongressEngagementStrategy) -> [LogicEntry] {
        entries.filter { $0.engagementStrategy == strategy }
    }
    
    /// Get entries in time range
    func entries(from start: Date, to end: Date) -> [LogicEntry] {
        entries.filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    /// Get most recent entry
    var mostRecentEntry: LogicEntry? {
        entries.max { $0.timestamp < $1.timestamp }
    }
    
    /// Get entries sorted by timestamp (newest first)
    var entriesSorted: [LogicEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Statistics
    var statistics: LogicLibraryStatistics {
        LogicLibraryStatistics(library: self)
    }
    
    // MARK: - Belief Integration
    
    /// Link relevant beliefs to a perspective (especially for Advocate/Skeptic)
    /// Returns updated perspective with linkedBeliefIds set based on alignment
    func linkBeliefsToPerspective(
        _ perspective: CongressPerspective,
        using beliefSystem: BeliefSystem
    ) -> CongressPerspective {
        var updated = perspective
        
        // Only Advocate and Skeptic strongly pull from beliefs
        guard perspective.role == .advocate || perspective.role == .skeptic else {
            return updated
        }
        
        // Find beliefs that align with this perspective's position
        let relevantBeliefs = beliefSystem.beliefs.filter { belief in
            // Match if belief stance is mentioned in position/reasoning
            let combinedText = (perspective.position + " " + perspective.reasoning).lowercased()
            return combinedText.contains(belief.stance.lowercased()) ||
                   combinedText.contains(belief.reasoning.lowercased())
        }
        
        updated.linkedBeliefIds = relevantBeliefs.map { $0.id }
        return updated
    }
    
    /// Strengthen a perspective based on aligned beliefs
    func strengthenPerspectiveWithBeliefs(
        _ perspective: CongressPerspective,
        using beliefSystem: BeliefSystem
    ) -> CongressPerspective {
        let alignedBeliefs = beliefSystem.beliefs.filter { 
            perspective.linkedBeliefIds.contains($0.id)
        }
        
        let newStrength = perspective.strengthenedWithBeliefs(alignedBeliefs)
        
        var strengthened = perspective
        // Since we can't mutate strengthOfArgument directly, create a new perspective with updated strength
        strengthened = CongressPerspective(
            role: perspective.role,
            position: perspective.position,
            reasoning: perspective.reasoning,
            strengthOfArgument: newStrength,
            callNumber: perspective.callNumber,
            linkedBeliefIds: perspective.linkedBeliefIds,
            timestamp: perspective.timestamp
        )
        
        return strengthened
    }
    
    /// Create an Advocate perspective with automatic belief linking
    func createAdvocatePerspective(
        position: String,
        reasoning: String,
        strengthOfArgument: Double = 8.0,
        callNumber: Int = 1,
        beliefSystem: BeliefSystem? = nil
    ) -> CongressPerspective {
        var perspective = CongressPerspective(
            role: .advocate,
            position: position,
            reasoning: reasoning,
            strengthOfArgument: strengthOfArgument,
            callNumber: callNumber
        )
        
        if let beliefsToLink = beliefSystem {
            perspective = linkBeliefsToPerspective(perspective, using: beliefsToLink)
            perspective = strengthenPerspectiveWithBeliefs(perspective, using: beliefsToLink)
        }
        
        return perspective
    }
    
    /// Create a Skeptic perspective with automatic belief linking
    func createSkepticPerspective(
        position: String,
        reasoning: String,
        strengthOfArgument: Double = 8.0,
        callNumber: Int = 1,
        beliefSystem: BeliefSystem? = nil
    ) -> CongressPerspective {
        var perspective = CongressPerspective(
            role: .skeptic,
            position: position,
            reasoning: reasoning,
            strengthOfArgument: strengthOfArgument,
            callNumber: callNumber
        )
        
        if let beliefsToLink = beliefSystem {
            perspective = linkBeliefsToPerspective(perspective, using: beliefsToLink)
            perspective = strengthenPerspectiveWithBeliefs(perspective, using: beliefsToLink)
        }
        
        return perspective
    }
    
    // MARK: - Persistence
    
    func exportAsJSON() -> Data? {
        try? JSONEncoder().encode(entries)
    }
    
    func importFromJSON(_ data: Data) throws {
        entries = try JSONDecoder().decode([LogicEntry].self, from: data)
    }
}

// MARK: - Statistics
struct LogicLibraryStatistics: Codable {
    let totalEntries: Int
    let simpleCount: Int
    let moderateCount: Int
    let complexCount: Int
    let averageWeight: Double
    let directResponseCount: Int
    let singleDebateCount: Int
    let multiCallCount: Int
    let totalPerspectivesRecorded: Int
    let totalCongressCalls: Int
    let averageResponseDrafts: Double
    let mostCommonParadigm: String?
    
    init(library: LogicLibrary) {
        self.totalEntries = library.entries.count
        self.simpleCount = library.entries(in: .simple).count
        self.moderateCount = library.entries(in: .moderate).count
        self.complexCount = library.entries(in: .complex).count
        self.averageWeight = library.entries.isEmpty ? 0 : 
            library.entries.map { $0.weight }.reduce(0, +) / Double(library.entries.count)
        
        self.directResponseCount = library.entries(with: .direct).count
        self.singleDebateCount = library.entries(with: .singleDebate).count
        self.multiCallCount = library.entries(with: .multiCall).count
        
        let allPerspectives = library.entries.flatMap { $0.allPerspectives }
        self.totalPerspectivesRecorded = allPerspectives.count
        
        let totalCalls = library.entries.reduce(0) { $0 + $1.congressCallCount }
        self.totalCongressCalls = totalCalls
        
        let avgDrafts = library.entries.isEmpty ? 0 :
            Double(library.entries.map { $0.draftCount }.reduce(0, +)) / Double(library.entries.count)
        self.averageResponseDrafts = avgDrafts
        
        let paradigmCounts = Dictionary(grouping: library.entries, by: { $0.paradigmRouting })
        self.mostCommonParadigm = paradigmCounts.max { $0.value.count < $1.value.count }?.key
    }
}
