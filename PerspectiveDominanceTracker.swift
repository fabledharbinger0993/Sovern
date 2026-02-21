import Foundation

// MARK: - Congress Analytics

struct CongressAnalytics {
    let perspectiveFrequency: [CongressRole: Int]
    let dominantPerspective: CongressRole
    let strengthPatterns: [CongressRole: [Double]]
    let decisionInfluence: [CongressRole: Double]
    let totalInteractions: Int
}

// MARK: - Perspective Dominance Tracker

/// Tracks which Congress perspective dominates Sovern's reasoning over time
class PerspectiveDominanceTracker: ObservableObject {
    
    @Published var analytics: CongressAnalytics
    
    private var allInteractionPerspectives: [CongressRole: [Double]] = [:]
    private var perspectiveWins: [CongressRole: Int] = [:]
    private var totalTracked: Int = 0
    
    init() {
        // Initialize tracking structures
        for role in CongressRole.allCases {
            self.allInteractionPerspectives[role] = []
            self.perspectiveWins[role] = 0
        }
        
        self.analytics = CongressAnalytics(
            perspectiveFrequency: [:],
            dominantPerspective: .advocate,
            strengthPatterns: [:],
            decisionInfluence: [:],
            totalInteractions: 0
        )
    }
    
    /// Track a new Congress interaction
    func trackInteraction(logicEntry: LogicEntry) {
        totalTracked += 1
        
        // 1. Find strongest perspective in this interaction
        guard let strongest = logicEntry.perspectives.max(by: {
            $0.strengthOfArgument < $1.strengthOfArgument
        }) else { return }
        
        // 2. Record frequency
        perspectiveWins[strongest.role, default: 0] += 1
        
        // 3. Record strength for this role
        for perspective in logicEntry.perspectives {
            allInteractionPerspectives[perspective.role, default: []].append(
                perspective.strengthOfArgument
            )
        }
        
        // 4. Recalculate analytics
        updateAnalytics(with: logicEntry, strongestRole: strongest.role)
    }
    
    /// Update the analytics with current data
    private func updateAnalytics(with logicEntry: LogicEntry, strongestRole: CongressRole) {
        // Frequency
        let frequency = perspectiveWins
        
        // Dominant perspective
        let dominant = frequency.max(by: { $0.value < $1.value })?.key ?? .advocate
        
        // Strength patterns (average strength per role)
        var strengthPatterns: [CongressRole: [Double]] = [:]
        for (role, strengths) in allInteractionPerspectives {
            strengthPatterns[role] = strengths
        }
        
        // Decision influence (% of interactions where this role was strongest)
        var influence: [CongressRole: Double] = [:]
        for role in CongressRole.allCases {
            let winCount = Double(perspectiveWins[role] ?? 0)
            let winPercent = totalTracked > 0 ? (winCount / Double(totalTracked)) * 100 : 0
            influence[role] = winPercent
        }
        
        self.analytics = CongressAnalytics(
            perspectiveFrequency: frequency,
            dominantPerspective: dominant,
            strengthPatterns: strengthPatterns,
            decisionInfluence: influence,
            totalInteractions: totalTracked
        )
    }
    
    /// Generate self-insight from dominance patterns
    func generateSelfInsight() -> Insight {
        let dominant = analytics.dominantPerspective
        let frequency = analytics.perspectiveFrequency[dominant] ?? 0
        let percent = analytics.totalInteractions > 0 ? 
            Double(frequency) / Double(analytics.totalInteractions) * 100 : 0
        
        let outcome = evaluateOutcome(of: dominant)
        
        let content = "I notice I've been \(dominant.description.lowercased())-dominant lately (~\(Int(percent))% of debates). " +
                      "This tends to produce \(outcome) results. " +
                      "Is this serving me well, or should I balance differently?"
        
        return Insight(
            content: content,
            category: .reasoningPattern,
            source: "Congress dominance analysis across \(analytics.totalInteractions) interactions"
        )
    }
    
    /// Evaluate the outcome tendency of a perspective
    private func evaluateOutcome(of role: CongressRole) -> String {
        switch role {
        case .advocate:
            return "collaborative and supportive, but sometimes less critical"
        case .skeptic:
            return "thorough and challenging, but can be overly defensive"
        case .synthesizer:
            return "balanced and integrative, finding common ground"
        case .ethics:
            return "values-aligned and principled, but sometimes restrictive"
        }
    }
    
    /// Get summary of perspective balance
    func getBalanceSummary() -> String {
        let freq = analytics.perspectiveFrequency
        guard !freq.isEmpty else { return "No interactions tracked" }
        
        let sorted = freq.sorted { $0.value > $1.value }
        let dominant = sorted.first?.key.description ?? "Unknown"
        
        let summary = sorted.map { role, count in
            let percent = analytics.totalInteractions > 0 ?
                Int(Double(count) / Double(analytics.totalInteractions) * 100) : 0
            return "\(role.description): \(percent)%"
        }.joined(separator: " | ")
        
        return "\(dominant)-dominant | \(summary)"
    }
    
    /// Reset tracking
    func reset() {
        allInteractionPerspectives = [:]
        perspectiveWins = [:]
        totalTracked = 0
        
        for role in CongressRole.allCases {
            allInteractionPerspectives[role] = []
            perspectiveWins[role] = 0
        }
    }
}

// MARK: - CongressRole Extension for description

extension CongressRole {
    var description: String {
        switch self {
        case .advocate: return "Advocate"
        case .skeptic: return "Skeptic"
        case .synthesizer: return "Synthesizer"
        case .ethics: return "Ethics"
        }
    }
}
