import Foundation

// MARK: - Belief Tension Analysis

/// Analyzes oscillation and tension in belief weights
struct BeliefTensionAnalysis {
    let oscillationCount: Int          // How many direction reversals?
    let oscillationAmplitude: Double   // Range of swings
    let stabilityScore: Double         // 0-1 (1=stable, 0=chaotic)
    let unresolvedFlag: Bool           // 3+ oscillations = unresolved
    let lastDominantDirection: String  // "increasing" or "decreasing"
    let tensionReason: String?         // What's conflicting?
}

// MARK: - Extension to BeliefNode

extension BeliefNode {
    
    /// Analyzes oscillation patterns and tension in this belief's history
    func analyzeTension() -> BeliefTensionAnalysis {
        let revisions = revisionHistory.sorted { $0.timestamp < $1.timestamp }
        
        // Detect direction changes (oscillations)
        var directionChanges = 0
        for i in 1..<revisions.count {
            let prevDirection = revisions[i-1].newWeight > revisions[i-1].previousWeight ? "up" : "down"
            let currDirection = revisions[i].newWeight > revisions[i].previousWeight ? "up" : "down"
            if prevDirection != currDirection {
                directionChanges += 1
            }
        }
        
        // Calculate amplitude (min-max spread)
        let allWeights = revisions.map { $0.newWeight }
        let amplitude = (allWeights.max() ?? weight) - (allWeights.min() ?? weight)
        
        // Determine if unresolved (3+ direction changes)
        let isUnresolved = directionChanges >= 3
        
        // Calculate stability score
        let stabilityScore = max(0.0, 1.0 - min(1.0, Double(directionChanges) / 10.0))
        
        // Last dominant direction
        let lastDirection = revisions.last.map { 
            $0.newWeight > $0.previousWeight ? "increasing" : "decreasing"
        } ?? "stable"
        
        // Identify what's causing tension
        let tension = identifyConflict(in: revisions)
        
        return BeliefTensionAnalysis(
            oscillationCount: directionChanges,
            oscillationAmplitude: amplitude,
            stabilityScore: stabilityScore,
            unresolvedFlag: isUnresolved,
            lastDominantDirection: lastDirection,
            tensionReason: tension
        )
    }
    
    /// Identifies if there's conflicting reasoning in revision history
    private func identifyConflict(in revisions: [BeliefRevision]) -> String? {
        guard revisions.count >= 3 else { return nil }
        
        let lastThree = Array(revisions.suffix(3))
        let reasons = lastThree.map { $0.reason.lowercased() }
        
        // Pattern 1: Logic vs. Values conflict
        let hasLogic = reasons.contains { $0.contains("logic") || $0.contains("reason") }
        let hasValues = reasons.contains { $0.contains("value") || $0.contains("empathy") }
        if hasLogic && hasValues {
            return "Tension between logic and values"
        }
        
        // Pattern 2: Theory vs. Practice conflict
        let hasTheory = reasons.contains { $0.contains("theory") || $0.contains("should") }
        let hasPractice = reasons.contains { $0.contains("practice") || $0.contains("experience") }
        if hasTheory && hasPractice {
            return "Tension between theory and practice"
        }
        
        // Pattern 3: Growth vs. Safety conflict
        let hasGrowth = reasons.contains { $0.contains("growth") || $0.contains("potential") }
        let hasSafety = reasons.contains { $0.contains("safe") || $0.contains("risk") }
        if hasGrowth && hasSafety {
            return "Tension between growth and safety"
        }
        
        // Pattern 4: Self vs. Other conflict
        let hasSelf = reasons.contains { $0.contains("self") || $0.contains("personal") }
        let hasOther = reasons.contains { $0.contains("other") || $0.contains("relational") }
        if hasSelf && hasOther {
            return "Tension between self-interest and relational concerns"
        }
        
        return nil
    }
    
    /// Returns a human-readable description of the tension state
    func tensionDescription() -> String {
        let tension = analyzeTension()
        
        if !tension.unresolvedFlag {
            return "Stable: \(String(format: "%.1f", weight))"
        }
        
        var description = "⚠️ Unresolved oscillation"
        
        if let reason = tension.tensionReason {
            description += " (\(reason))"
        }
        
        if tension.oscillationAmplitude > 2.0 {
            description += " — High flux"
        }
        
        description += " (swung \(tension.oscillationCount) times, amplitude ±\(String(format: "%.1f", tension.oscillationAmplitude / 2)))"
        
        return description
    }
}
