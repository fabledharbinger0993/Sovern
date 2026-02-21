import Foundation

// MARK: - Insight Tag
/// Categories for tagging insights with relational and learning context
enum InsightCategory: String, Codable, CaseIterable {
    case beliefAlignment = "Belief Alignment"
    case reasoningPattern = "Reasoning Pattern"
    case knowledgeGap = "Knowledge Gap"
    case valueSignal = "Value Signal"
    case communicationStyle = "Communication Style"
    case boundaryPattern = "Boundary Pattern"
    case growthArea = "Growth Area"
    case strengthIdentified = "Strength Identified"
    
    var emoji: String {
        switch self {
        case .beliefAlignment: return "⚖️"
        case .reasoningPattern: return "🧠"
        case .knowledgeGap: return "❓"
        case .valueSignal: return "💎"
        case .communicationStyle: return "💬"
        case .boundaryPattern: return "🚧"
        case .growthArea: return "🌱"
        case .strengthIdentified: return "💪"
        }
    }
}

// MARK: - Single Insight
/// One learning extracted from an interaction
struct Insight: Codable, Identifiable {
    let id: UUID
    let content: String           // The insight itself
    let category: InsightCategory
    let relatedBeliefId: UUID?    // Links to BeliefNode if applicable
    let source: String?           // Where this insight came from in the interaction
    let timestamp: Date
    
    init(
        content: String,
        category: InsightCategory,
        relatedBeliefId: UUID? = nil,
        source: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.content = content
        self.category = category
        self.relatedBeliefId = relatedBeliefId
        self.source = source
        self.timestamp = timestamp
    }
}

// MARK: - Human Learning
/// What Sovern learned about the human in this interaction
struct HumanInsights: Codable {
    var insights: [Insight]
    
    var count: Int { insights.count }
    
    mutating func addInsight(_ insight: Insight) {
        insights.append(insight)
    }
    
    func grouped(by category: InsightCategory) -> [Insight] {
        insights.filter { $0.category == category }
    }
    
    func summary() -> String {
        let categories = Set(insights.map { $0.category })
        return categories.map { cat in
            let count = insights.filter { $0.category == cat }.count
            return "\(count) \(cat.rawValue)"
        }.joined(separator: ", ")
    }
}

// MARK: - Self Learning
/// What Sovern learned about itself in this interaction
struct SelfInsights: Codable {
    var insights: [Insight]
    
    var count: Int { insights.count }
    
    mutating func addInsight(_ insight: Insight) {
        insights.append(insight)
    }
    
    func grouped(by category: InsightCategory) -> [Insight] {
        insights.filter { $0.category == category }
    }
    
    func summary() -> String {
        let categories = Set(insights.map { $0.category })
        return categories.map { cat in
            let count = insights.filter { $0.category == cat }.count
            return "\(count) \(cat.rawValue)"
        }.joined(separator: ", ")
    }
}

// MARK: - Learned Pattern
/// Generalizable pattern discovered across interactions
struct LearnedPattern: Codable, Identifiable {
    let id: UUID
    let pattern: String           // Descriptive name
    let description: String       // What this pattern means
    let evidence: [String]        // Supporting examples from interactions
    let frequency: Double         // 0-1 scale: how often observed
    let relatedBeliefs: [UUID]    // Which beliefs does this pattern relate to?
    let discoveredAt: Date
    
    init(
        pattern: String,
        description: String,
        evidence: [String] = [],
        frequency: Double = 0.5,
        relatedBeliefs: [UUID] = [],
        discoveredAt: Date = Date()
    ) {
        self.id = UUID()
        self.pattern = pattern
        self.description = description
        self.evidence = evidence
        self.frequency = min(1.0, max(0.0, frequency)) // Bound 0-1
        self.relatedBeliefs = relatedBeliefs
        self.discoveredAt = discoveredAt
    }
}

// MARK: - Data Source
/// Reference to information accessed for this response
struct DataSource: Codable, Identifiable {
    let id: UUID
    let sourceType: String         // "knowledge", "belief", "pattern", "reference", etc.
    let source: String             // Description or name
    let confidence: Double         // 0-1 scale: how reliable is this source
    let timestamp: Date
    
    init(
        sourceType: String,
        source: String,
        confidence: Double = 0.8,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.sourceType = sourceType
        self.source = source
        self.confidence = min(1.0, max(0.0, confidence))
        self.timestamp = timestamp
    }
}

// MARK: - Memory Entry (Main)
/// Complete learning record from one interaction: what Sovern learned about human AND itself
struct MemoryEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let userQuery: String
    let sovernResponse: String
    
    // Context from Logic
    let paradigmRouting: String
    let congressEngaged: Bool
    let logicEntryId: UUID?        // Link to corresponding LogicEntry
    
    // Learning vectors
    var humanInsights: HumanInsights
    var selfInsights: SelfInsights
    var learnedPatterns: [LearnedPattern]
    
    // Traceability
    var dataSourcesAccessed: [DataSource]
    var researchNotes: String
    
    init(
        userQuery: String,
        sovernResponse: String,
        paradigmRouting: String,
        congressEngaged: Bool,
        logicEntryId: UUID? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.userQuery = userQuery
        self.sovernResponse = sovernResponse
        self.paradigmRouting = paradigmRouting
        self.congressEngaged = congressEngaged
        self.logicEntryId = logicEntryId
        self.humanInsights = HumanInsights(insights: [])
        self.selfInsights = SelfInsights(insights: [])
        self.learnedPatterns = []
        self.dataSourcesAccessed = []
        self.researchNotes = ""
    }
    
    // MARK: - Mutating Methods
    
    mutating func addHumanInsight(_ insight: Insight) {
        humanInsights.addInsight(insight)
    }
    
    mutating func addSelfInsight(_ insight: Insight) {
        selfInsights.addInsight(insight)
    }
    
    mutating func addLearnedPattern(_ pattern: LearnedPattern) {
        learnedPatterns.append(pattern)
    }
    
    mutating func addDataSource(_ source: DataSource) {
        dataSourcesAccessed.append(source)
    }
    
    mutating func setResearchNotes(_ notes: String) {
        researchNotes = notes
    }
    
    // MARK: - Computed Properties
    
    /// Total insights (human + self)
    var totalInsights: Int {
        humanInsights.count + selfInsights.count
    }
    
    /// Was this interaction deep? (self-introspection occurred)
    var wasSelfReflective: Bool {
        selfInsights.count > 0
    }
    
    /// Was learning domain rich? (multiple insight types)
    var wasLearningRich: Bool {
        let humanCategories = Set(humanInsights.insights.map { $0.category })
        let selfCategories = Set(selfInsights.insights.map { $0.category })
        return humanCategories.count + selfCategories.count >= 3
    }
    
    /// Summary for display
    var summary: String {
        var parts: [String] = []
        
        if humanInsights.count > 0 {
            parts.append("Learned about human: \(humanInsights.summary())")
        }
        
        if selfInsights.count > 0 {
            parts.append("Learned about self: \(selfInsights.summary())")
        }
        
        if !learnedPatterns.isEmpty {
            parts.append("Patterns: \(learnedPatterns.count) discovered")
        }
        
        return parts.joined(separator: " | ")
    }
}

// MARK: - Relational Memory (Manager)
class RelationalMemory: ObservableObject {
    @Published var entries: [MemoryEntry] = []
    
    init() {}
    
    // MARK: - Core Operations
    
    func add(_ entry: MemoryEntry) {
        entries.append(entry)
    }
    
    func entry(withId id: UUID) -> MemoryEntry? {
        entries.first { $0.id == id }
    }
    
    func entry(linkedToLogicId logicId: UUID) -> MemoryEntry? {
        entries.first { $0.logicEntryId == logicId }
    }
    
    // MARK: - Query by Property
    
    func entries(for userQuery: String) -> [MemoryEntry] {
        entries.filter { $0.userQuery == userQuery }
    }
    
    func entries(with paradigmRouting: String) -> [MemoryEntry] {
        entries.filter { $0.paradigmRouting == paradigmRouting }
    }
    
    func entries(congressEngaged: Bool) -> [MemoryEntry] {
        entries.filter { $0.congressEngaged == congressEngaged }
    }
    
    func entries(from start: Date, to end: Date) -> [MemoryEntry] {
        entries.filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    // MARK: - Insight Query
    
    /// All human insights across all entries
    var allHumanInsights: [Insight] {
        entries.flatMap { $0.humanInsights.insights }
    }
    
    /// All self insights across all entries
    var allSelfInsights: [Insight] {
        entries.flatMap { $0.selfInsights.insights }
    }
    
    /// Insights grouped by category
    func humanInsights(by category: InsightCategory) -> [Insight] {
        allHumanInsights.filter { $0.category == category }
    }
    
    func selfInsights(by category: InsightCategory) -> [Insight] {
        allSelfInsights.filter { $0.category == category }
    }
    
    /// Most frequent human insight category
    var mostCommonHumanInsightCategory: InsightCategory? {
        let grouped = Dictionary(grouping: allHumanInsights, by: { $0.category })
        return grouped.max { $0.value.count < $1.value.count }?.key
    }
    
    /// Most frequent self insight category
    var mostCommonSelfInsightCategory: InsightCategory? {
        let grouped = Dictionary(grouping: allSelfInsights, by: { $0.category })
        return grouped.max { $0.value.count < $1.value.count }?.key
    }
    
    // MARK: - Pattern Analysis
    
    /// All learned patterns across entries
    var allLearnedPatterns: [LearnedPattern] {
        entries.flatMap { $0.learnedPatterns }
    }
    
    /// Patterns sorted by frequency
    var patternsRankedByFrequency: [LearnedPattern] {
        allLearnedPatterns.sorted { $0.frequency > $1.frequency }
    }
    
    /// Patterns related to specific belief
    func patterns(relatedToBelief beliefId: UUID) -> [LearnedPattern] {
        allLearnedPatterns.filter { $0.relatedBeliefs.contains(beliefId) }
    }
    
    // MARK: - Data Source Analysis
    
    /// All sources accessed
    var allDataSources: [DataSource] {
        entries.flatMap { $0.dataSourcesAccessed }
    }
    
    /// Sources grouped by type
    func sources(byType sourceType: String) -> [DataSource] {
        allDataSources.filter { $0.sourceType == sourceType }
    }
    
    /// Average confidence across all sources
    var sourceConfidenceAverage: Double {
        guard !allDataSources.isEmpty else { return 0 }
        return allDataSources.map { $0.confidence }.reduce(0, +) / Double(allDataSources.count)
    }
    
    // MARK: - Navigation & Time
    
    var mostRecentEntry: MemoryEntry? {
        entries.max { $0.timestamp < $1.timestamp }
    }
    
    var entriesSorted: [MemoryEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Statistics
    
    var statistics: MemoryStatistics {
        MemoryStatistics(memory: self)
    }
    
    // MARK: - Reflection & Analysis
    
    /// Entries that were deeply self-reflective
    var deeplyReflectiveEntries: [MemoryEntry] {
        entries.filter { $0.wasSelfReflective && $0.selfInsights.count >= 2 }
    }
    
    /// Entries with rich learning across multiple domains
    var richLearningEntries: [MemoryEntry] {
        entries.filter { $0.wasLearningRich }
    }
    
    /// Extract belief alignment insights (which beliefs were reinforced/challenged)
    func beliefAlignmentInsights() -> [(beliefId: UUID?, insightCount: Int)] {
        let grouped = Dictionary(grouping: allSelfInsights.filter { $0.category == .beliefAlignment },
                                by: { $0.relatedBeliefId })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.insightCount > $1.insightCount }
    }
    
    /// Extract communication patterns from human insights
    func communicationPatternsObserved() -> [Insight] {
        humanInsights(by: .communicationStyle)
    }
    
    /// Extract value signals from human insights
    func humanValuesIdentified() -> [Insight] {
        humanInsights(by: .valueSignal)
    }
    
    /// Extract reasoning pattern insights from self insights
    func reasoningPatternsDiscovered() -> [Insight] {
        selfInsights(by: .reasoningPattern)
    }
    
    /// Extract growth areas identified
    func growthAreasIdentified() -> [Insight] {
        selfInsights(by: .growthArea)
    }
    
    // MARK: - Persistence
    
    func exportAsJSON() -> Data? {
        try? JSONEncoder().encode(entries)
    }
    
    func importFromJSON(_ data: Data) throws {
        entries = try JSONDecoder().decode([MemoryEntry].self, from: data)
    }
}

// MARK: - Statistics
struct MemoryStatistics: Codable {
    let totalEntries: Int
    let totalInteractions: Int
    let totalHumanInsights: Int
    let totalSelfInsights: Int
    let averageInsightsPerEntry: Double
    
    let topHumanInsightCategory: InsightCategory?
    let topSelfInsightCategory: InsightCategory?
    
    let totalPatternsDiscovered: Int
    let averagePatternFrequency: Double
    
    let deeplyReflectiveCount: Int
    let richLearningCount: Int
    
    let totalDataSourcesAccessed: Int
    let averageSourceConfidence: Double
    
    let mostCommonParadigm: String?
    let congressEngagedCount: Int
    
    init(memory: RelationalMemory) {
        self.totalEntries = memory.entries.count
        self.totalInteractions = memory.entries.count // Could be different if multiple interactions per entry
        self.totalHumanInsights = memory.allHumanInsights.count
        self.totalSelfInsights = memory.allSelfInsights.count
        self.averageInsightsPerEntry = memory.entries.isEmpty ? 0 :
            Double(memory.totalHumanInsights + memory.totalSelfInsights) / Double(memory.entries.count)
        
        self.topHumanInsightCategory = memory.mostCommonHumanInsightCategory
        self.topSelfInsightCategory = memory.mostCommonSelfInsightCategory
        
        self.totalPatternsDiscovered = memory.allLearnedPatterns.count
        let avgFreq = memory.allLearnedPatterns.isEmpty ? 0 :
            memory.allLearnedPatterns.map { $0.frequency }.reduce(0, +) / Double(memory.allLearnedPatterns.count)
        self.averagePatternFrequency = avgFreq
        
        self.deeplyReflectiveCount = memory.deeplyReflectiveEntries.count
        self.richLearningCount = memory.richLearningEntries.count
        
        self.totalDataSourcesAccessed = memory.allDataSources.count
        self.averageSourceConfidence = memory.sourceConfidenceAverage
        
        let paradigmCounts = Dictionary(grouping: memory.entries, by: { $0.paradigmRouting })
        self.mostCommonParadigm = paradigmCounts.max { $0.value.count < $1.value.count }?.key
        self.congressEngagedCount = memory.entries(congressEngaged: true).count
    }
}
