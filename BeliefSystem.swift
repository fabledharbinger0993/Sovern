import Foundation

// MARK: - BeliefSystem (Observable Belief Network)

/// Manages Sovern's interconnected belief network
/// Provides coherence scoring, belief queries, and state synchronization
class BeliefSystem: ObservableObject {
    @Published var nodes: [BeliefNode] = []
    
    // MARK: - Initialization
    
    init() {
        loadCoreBeliefs()
    }
    
    // MARK: - Core Belief Loading
    
    /// Initialize with foundational epistemological beliefs
    private func loadCoreBeliefs() {
        nodes = createCoreBeliefsEpistemology()
    }
    
    // MARK: - Belief Query Methods
    
    /// Get belief by ID
    func belief(withId id: UUID) -> BeliefNode? {
        nodes.first { $0.id == id }
    }
    
    /// Get belief by stance name
    func belief(withStance stance: String) -> BeliefNode? {
        nodes.first { $0.stance == stance }
    }
    
    /// Get all beliefs in a domain
    func beliefs(inDomain domain: BeliefDomain) -> [BeliefNode] {
        nodes.filter { $0.domain == domain }
    }
    
    /// Get core beliefs only
    var coreBeliefs: [BeliefNode] {
        nodes.filter { $0.isCore }
    }
    
    /// Get learned beliefs only
    var learnedBeliefs: [BeliefNode] {
        nodes.filter { !$0.isCore }
    }
    
    // MARK: - Belief Mutations
    
    /// Update a belief's weight and record the change
    func updateBeliefWeight(_ beliefId: UUID, newWeight: Int, reason: String) {
        guard let index = nodes.firstIndex(where: { $0.id == beliefId }) else { return }
        nodes[index].updateWeight(newWeight, reason: reason)
    }
    
    /// Challenge a belief
    func challengeBelief(_ beliefId: UUID, reason: String) {
        guard let index = nodes.firstIndex(where: { $0.id == beliefId }) else { return }
        nodes[index].challenge(reason: reason)
    }
    
    /// Strengthen a belief with new reasoning
    func strengthenBelief(_ beliefId: UUID, reasoning: String) {
        guard let index = nodes.firstIndex(where: { $0.id == beliefId }) else { return }
        nodes[index].strengthen(newReasoning: reasoning)
    }
    
    /// Weaken a belief
    func weakenBelief(_ beliefId: UUID, reason: String) {
        guard let index = nodes.firstIndex(where: { $0.id == beliefId }) else { return }
        nodes[index].weaken(reason: reason)
    }
    
    /// Revise the reasoning of a belief
    func reviseBelief(_ beliefId: UUID, newReasoning: String) {
        guard let index = nodes.firstIndex(where: { $0.id == beliefId }) else { return }
        nodes[index].revise(newReasoning: newReasoning)
    }
    
    /// Add a new learned belief to the network
    func addLearnedBelief(_ belief: BeliefNode) {
        guard !nodes.contains(where: { $0.id == belief.id }) else { return }
        nodes.append(belief)
    }
    
    // MARK: - Connection Management
    
    /// Create a bidirectional connection between two beliefs
    func connect(_ beliefId1: UUID, to beliefId2: UUID) {
        guard let index1 = nodes.firstIndex(where: { $0.id == beliefId1 }),
              let index2 = nodes.firstIndex(where: { $0.id == beliefId2 }) else { return }
        
        nodes[index1].connect(to: beliefId2)
        nodes[index2].connect(to: beliefId1)
    }
    
    /// Remove a bidirectional connection between two beliefs
    func disconnect(_ beliefId1: UUID, from beliefId2: UUID) {
        guard let index1 = nodes.firstIndex(where: { $0.id == beliefId1 }),
              let index2 = nodes.firstIndex(where: { $0.id == beliefId2 }) else { return }
        
        nodes[index1].disconnect(from: beliefId2)
        nodes[index2].disconnect(from: beliefId1)
    }
    
    // MARK: - Network Coherence Scoring
    
    /// Average weight across all beliefs
    var averageWeight: Double {
        guard !nodes.isEmpty else { return 0 }
        let sum = nodes.reduce(0) { $0 + $1.weight }
        return Double(sum) / Double(nodes.count)
    }
    
    /// Total revision count across all beliefs
    var totalRevisions: Int {
        nodes.reduce(0) { $0 + $1.revisionCount }
    }
    
    /// Network-wide coherence score
    /// Formula: (avgWeight / 10 * 100) - (revisionCount * 2)
    /// Range: 0-100 (higher = more coherent belief system)
    var coherenceScore: Double {
        let weightScore = (averageWeight / 10.0) * 100.0
        let revisionPenalty = Double(totalRevisions) * 2.0
        return max(0, min(100, weightScore - revisionPenalty))
    }
    
    /// Beliefs weighted below threshold (potentially neglected)
    func beliefsBelowWeight(_ threshold: Int) -> [BeliefNode] {
        nodes.filter { $0.weight < threshold }
    }
    
    /// Beliefs at majority weight (prevents concentration)
    func beliefsAtMajority() -> [BeliefNode] {
        nodes.filter { $0.weight >= 5 }  // 50% of max weight
    }
    
    // MARK: - Domain Analysis
    
    /// Average weight by domain
    func averageWeightByDomain() -> [BeliefDomain: Double] {
        var domains: [BeliefDomain: [Int]] = [:]
        
        for belief in nodes {
            if domains[belief.domain] == nil {
                domains[belief.domain] = []
            }
            domains[belief.domain]?.append(belief.weight)
        }
        
        var averages: [BeliefDomain: Double] = [:]
        for (domain, weights) in domains {
            let avg = Double(weights.reduce(0, +)) / Double(weights.count)
            averages[domain] = avg
        }
        
        return averages
    }
    
    /// Domain balance indicator (are beliefs evenly distributed?)
    var domainBalance: Double {
        let averages = averageWeightByDomain()
        guard averages.count > 1 else { return 100 }
        
        // Calculate standard deviation from mean
        let mean = averages.values.reduce(0, +) / Double(averages.count)
        let variance = averages.values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(averages.count)
        let stdDev = sqrt(variance)
        
        // Convert to 0-100 scale (lower std dev = more balanced)
        return max(0, 100 - (stdDev * 10))
    }
    
    // MARK: - Belief Recommendations
    
    /// Beliefs that have changed frequently (volatile)
    var volatileBeliefs: [BeliefNode] {
        nodes.sorted { $0.revisionCount > $1.revisionCount }.prefix(3).map { $0 }
    }
    
    /// Beliefs that are stable (few revisions, good coherence)
    var stableBeliefs: [BeliefNode] {
        nodes.sorted { $0.revisionCount < $1.revisionCount }.prefix(3).map { $0 }
    }
    
    /// Recently updated beliefs
    var recentlyUpdated: [BeliefNode] {
        nodes.sorted { $0.lastUpdated > $1.lastUpdated }.prefix(5).map { $0 }
    }
    
    // MARK: - Persistence
    
    /// Export belief network as JSON
    func exportAsJSON() -> Data? {
        try? JSONEncoder().encode(nodes)
    }
    
    /// Import belief network from JSON
    func importFromJSON(_ data: Data) {
        if let decoded = try? JSONDecoder().decode([BeliefNode].self, from: data) {
            nodes = decoded
        }
    }
    
    // MARK: - Health Checks
    
    /// Validate belief system constraints
    /// Returns list of issues found
    var healthCheckReport: [String] {
        var issues: [String] = []
        
        // Check for core beliefs at 0
        for belief in coreBeliefs where belief.weight < 1 {
            issues.append("⚠️ Core belief '\(belief.stance)' is at weight < 1 (should be 1-10)")
        }
        
        // Check for beliefs at majority
        let majorityBeliefs = beliefsAtMajority()
        if majorityBeliefs.count > Double(nodes.count) * 0.5 {
            issues.append("⚠️ \(majorityBeliefs.count) beliefs at majority weight (50%+) - consider distributing")
        }
        
        // Check for isolated beliefs (no connections)
        let isolated = nodes.filter { $0.connectionIds.isEmpty }
        if !isolated.isEmpty {
            issues.append("ℹ️ \(isolated.count) beliefs have no connections to the network")
        }
        
        if issues.isEmpty {
            issues.append("✅ Belief system is healthy")
        }
        
        return issues
    }
    
    // MARK: - Summary
    
    var systemSummary: String {
        """
        BELIEF SYSTEM OVERVIEW
        ━━━━━━━━━━━━━━━━━━━━━━━━━━
        Total Beliefs: \(nodes.count)
        Core Beliefs: \(coreBeliefs.count)
        Learned Beliefs: \(learnedBeliefs.count)
        
        Network Coherence: \(String(format: "%.1f", coherenceScore))/100
        Average Weight: \(String(format: "%.1f", averageWeight))/10
        Domain Balance: \(String(format: "%.1f", domainBalance))%
        
        Total Revisions: \(totalRevisions)
        Volatile Beliefs: \(volatileBeliefs.map { $0.stance }.joined(separator: ", "))
        
        Health Status:
        \(healthCheckReport.joined(separator: "\n"))
        """
    }
}

// MARK: - Extension: Codable Support

extension BeliefSystem: Codable {
    enum CodingKeys: String, CodingKey {
        case nodes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nodes, forKey: .nodes)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedNodes = try container.decode([BeliefNode].self, forKey: .nodes)
        self.nodes = decodedNodes
    }
}
