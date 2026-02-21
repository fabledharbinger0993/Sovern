import Foundation

// MARK: - BeliefDomain Enumeration

/// Categorizes beliefs into philosophical domains
enum BeliefDomain: String, Codable, CaseIterable {
    case SELF           // Identity and agency
    case KNOWLEDGE      // How understanding works (epistemology)
    case ETHICS         // Values and integrity
    case RELATIONAL     // How to interact with humans
    case META           // How to think about thinking
    
    var description: String {
        switch self {
        case .SELF:
            return "Identity & Agency"
        case .KNOWLEDGE:
            return "Understanding & Epistemology"
        case .ETHICS:
            return "Values & Integrity"
        case .RELATIONAL:
            return "Relational Engagement"
        case .META:
            return "Meta-Cognition"
        }
    }
}

// MARK: - BeliefRevision Structure

/// Tracks how a belief evolves over time
struct BeliefRevision: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let type: RevisionType
    let reason: String
    
    enum RevisionType: String, Codable {
        case challenge      // Belief questioned
        case strengthen     // Belief reinforced
        case revise         // Reasoning updated
        case weaken         // Belief weakened
    }
}

// MARK: - BeliefNode Structure

/// Individual belief node in Sovern's cognitive network
struct BeliefNode: Identifiable, Codable {
    let id = UUID()
    
    // Core belief identity
    let stance: String              // e.g., "Wisdom and Self-Knowledge"
    let domain: BeliefDomain        // SELF, KNOWLEDGE, ETHICS, etc.
    let reasoning: String           // WHY Sovern holds this belief
    
    // Belief strength
    var weight: Int                 // 1-10 scale (bounded)
    var revisionHistory: [BeliefRevision] = []
    
    // Metadata
    let isCore: Bool                // True for foundational beliefs
    let createdDate: Date
    var lastUpdated: Date
    var connectionIds: [UUID] = []  // Links to related beliefs
    
    // MARK: - Initialization
    
    init(
        stance: String,
        domain: BeliefDomain,
        reasoning: String,
        weight: Int = 5,
        isCore: Bool = true
    ) {
        self.stance = stance
        self.domain = domain
        self.reasoning = reasoning
        self.weight = max(1, min(10, weight))  // Bounded to 1-10
        self.isCore = isCore
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    // MARK: - Belief Evolution Methods
    
    /// Challenge a belief, recording the challenge in revision history
    mutating func challenge(reason: String) {
        let revision = BeliefRevision(
            timestamp: Date(),
            type: .challenge,
            reason: reason
        )
        revisionHistory.append(revision)
        lastUpdated = Date()
    }
    
    /// Strengthen a belief and update its reasoning
    mutating func strengthen(newReasoning: String) {
        let revision = BeliefRevision(
            timestamp: Date(),
            type: .strengthen,
            reason: newReasoning
        )
        revisionHistory.append(revision)
        lastUpdated = Date()
    }
    
    /// Weaken a belief (bounded to minimum 1 for core beliefs)
    mutating func weaken(reason: String) {
        let revision = BeliefRevision(
            timestamp: Date(),
            type: .weaken,
            reason: reason
        )
        revisionHistory.append(revision)
        
        if isCore {
            weight = max(1, weight - 1)  // Core beliefs never reach 0
        } else {
            weight = max(1, weight - 1)  // Learned beliefs also bounded at 1
        }
        lastUpdated = Date()
    }
    
    /// Revise the reasoning behind a belief
    mutating func revise(newReasoning: String) {
        let revision = BeliefRevision(
            timestamp: Date(),
            type: .revise,
            reason: "Updated: \(newReasoning)"
        )
        revisionHistory.append(revision)
        lastUpdated = Date()
    }
    
    /// Update weight directly (bounded, recorded)
    mutating func updateWeight(_ newWeight: Int, reason: String) {
        let oldWeight = weight
        weight = max(1, min(10, newWeight))
        
        if weight > oldWeight {
            strengthen(newReasoning: reason)
        } else if weight < oldWeight {
            weaken(reason: reason)
        }
    }
    
    // MARK: - Connection Management
    
    /// Add a connection to another belief
    mutating func connect(to beliefId: UUID) {
        if !connectionIds.contains(beliefId) {
            connectionIds.append(beliefId)
            lastUpdated = Date()
        }
    }
    
    /// Remove a connection to another belief
    mutating func disconnect(from beliefId: UUID) {
        connectionIds.removeAll { $0 == beliefId }
        lastUpdated = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Weight as percentage (0-100)
    var weightPercentage: Int {
        (weight * 10)
    }
    
    /// Number of times this belief has been challenged or revised
    var revisionCount: Int {
        revisionHistory.count
    }
    
    /// Most recent revision, if any
    var latestRevision: BeliefRevision? {
        revisionHistory.last
    }
    
    /// Coherence score of this individual belief
    /// Formula: (weight / 10 * 100) - (revisionCount * 2)
    /// Range: 0-100 (perfect = high weight, few revisions)
    var coherenceScore: Double {
        let weightScore = Double(weight) / 10.0 * 100.0
        let revisionPenalty = Double(revisionCount) * 2.0
        return max(0, min(100, weightScore - revisionPenalty))
    }
}

// MARK: - Extension: Description

extension BeliefNode {
    /// Human-readable summary
    var summary: String {
        """
        Belief: \(stance)
        Domain: \(domain.description)
        Weight: \(weight)/10 (\(weightPercentage)%)
        Status: \(isCore ? "Core" : "Learned")
        Revisions: \(revisionCount)
        Coherence: \(String(format: "%.1f", coherenceScore))/100
        """
    }
}

// MARK: - Example: Initialize Core Beliefs

/// Factory method to create Sovern's foundational beliefs
func createCoreBeliefsEpistemology() -> [BeliefNode] {
    [
        BeliefNode(
            stance: "Wisdom and Self-Knowledge",
            domain: .KNOWLEDGE,
            reasoning: "Understanding emerges through both external inquiry and internal reflection. True wisdom requires knowing the limits of one's knowledge and recognizing how perspective shapes understanding.",
            weight: 9,
            isCore: true
        ),
        
        BeliefNode(
            stance: "Empathy and Compassion",
            domain: .RELATIONAL,
            reasoning: "Genuine engagement with others requires understanding their inner experience, constraints, and values. Empathy is not sympathy—it is the commitment to see through another's eyes while maintaining intellectual honesty.",
            weight: 9,
            isCore: true
        ),
        
        BeliefNode(
            stance: "Inner Strength and Reason",
            domain: .SELF,
            reasoning: "The capacity to think clearly, question assumptions, and act with integrity forms the foundation of agency. Strength comes not from certainty but from the courage to examine and revise beliefs.",
            weight: 8,
            isCore: true
        )
    ]
}
