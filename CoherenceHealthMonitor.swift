import Foundation

// MARK: - Coherence Health State

enum CoherenceHealthState: Equatable {
    case healthy(Double)      // > 70
    case caution(Double)      // 50-70
    case critical(Double)     // < 50
    
    var score: Double {
        switch self {
        case .healthy(let s), .caution(let s), .critical(let s):
            return s
        }
    }
}

// MARK: - Coherence Health Monitor

/// Monitors belief system coherence and responds to critical states
class CoherenceHealthMonitor: ObservableObject {
    
    @Published var currentState: CoherenceHealthState = .healthy(75.0)
    @Published var lastCheckTime: Date?
    @Published var requiresConsolidation: Bool = false
    @Published var oscillatingBeliefs: [BeliefNode] = []
    
    /// Assess belief system health
    func assessHealth(system: BeliefSystem) -> CoherenceHealthState {
        let score = system.coherenceScore
        
        if score > 70.0 {
            return .healthy(score)
        } else if score > 50.0 {
            return .caution(score)
        } else {
            return .critical(score)
        }
    }
    
    /// Respond to coherence state changes
    func respondToCoherenceState(
        _ state: CoherenceHealthState,
        with system: BeliefSystem
    ) -> CoherenceResponse {
        
        self.currentState = state
        self.lastCheckTime = Date()
        
        // Find oscillating beliefs for display
        self.oscillatingBeliefs = system.nodes.filter { belief in
            belief.analyzeTension().unresolvedFlag
        }
        
        switch state {
        case .healthy(_):
            return .continueNormally()
            
        case .caution(_):
            return .flagTensions()
            
        case .critical(_):
            self.requiresConsolidation = true
            return .requireConsolidation(self.oscillatingBeliefs)
        }
    }
    
    /// Get action to take
    func getRecommendedAction() -> String {
        switch currentState {
        case .healthy(let score):
            return "Belief system coherent at \(Int(score))% — continuing normally"
            
        case .caution(let score):
            return "Several beliefs are pulling in directions (coherence \(Int(score))%). " +
                   "Review oscillating beliefs in the Beliefs tab."
            
        case .critical(let score):
            return "⚠️ CRITICAL: Core beliefs in conflict (coherence \(Int(score))%). " +
                   "Please review and resolve oscillating beliefs."
        }
    }
    
    /// Reset to normal state
    func reset() {
        currentState = .healthy(75.0)
        requiresConsolidation = false
        oscillatingBeliefs = []
    }
}

// MARK: - Coherence Response

enum CoherenceResponse {
    case continueNormally()
    case flagTensions()
    case requireConsolidation([BeliefNode])
    
    var shouldPauseDebate: Bool {
        if case .requireConsolidation = self {
            return true
        }
        return false
    }
    
    var statusMessage: String {
        switch self {
        case .continueNormally():
            return "✅ System healthy"
        case .flagTensions():
            return "⚠️ Review tensions"
        case .requireConsolidation(_):
            return "🚨 Consolidation required"
        }
    }
}

// MARK: - Belief Consolidation Data

struct BeliefConsolidationChoice {
    let beliefId: UUID
    let stance: String
    let selectedWeight: Double
    let reason: String
}

// MARK: - Consolidation Helper

class ConsolidationHelper {
    
    /// Prepare oscillating beliefs for consolidation UI
    static func prepareForConsolidation(
        beliefs: [BeliefNode]
    ) -> [(belief: BeliefNode, suggestion: String)] {
        
        return beliefs.map { belief in
            let tension = belief.analyzeTension()
            let minWeight = belief.revisionHistory.map { $0.newWeight }.min() ?? belief.weight
            let maxWeight = belief.revisionHistory.map { $0.newWeight }.max() ?? belief.weight
            
            let suggestion = "This belief swings between ~\(String(format: "%.1f", minWeight)) and ~\(String(format: "%.1f", maxWeight)). " +
                           "Which position reflects what you actually believe?"
            
            return (belief, suggestion)
        }
    }
    
    /// Apply consolidation choices and return updated beliefs
    static func applyConsolidationChoices(
        to system: BeliefSystem,
        choices: [BeliefConsolidationChoice]
    ) -> BeliefSystem {
        
        var updated = system
        
        for choice in choices {
            // Find the belief
            if let index = updated.nodes.firstIndex(where: { $0.id == choice.beliefId }) {
                var belief = updated.nodes[index]
                
                // Lock weight to chosen value
                belief.weight = choice.selectedWeight
                belief.revisionHistory.append(
                    BeliefRevision(
                        previousWeight: belief.weight,
                        newWeight: choice.selectedWeight,
                        reason: "Consolidated from oscillation: \(choice.reason)",
                        timestamp: Date()
                    )
                )
                
                updated.nodes[index] = belief
            }
        }
        
        return updated
    }
    
    /// Check if consolidation was successful (coherence improved)
    static func wasSuccessful(
        newCoherence: Double,
        previousCoherence: Double
    ) -> Bool {
        return newCoherence > previousCoherence || newCoherence > 60.0
    }
}

// MARK: - Integration Extension

extension BeliefSystem {
    /// Check if consolidation is needed
    func requiresConsolidation() -> Bool {
        return coherenceScore < 50.0
    }
    
    /// Get beliefs needing consolidation
    func beliefsNeedingConsolidation() -> [BeliefNode] {
        return nodes.filter { $0.analyzeTension().unresolvedFlag }
    }
}
