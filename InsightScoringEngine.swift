import Foundation

// MARK: - Insight Scoring Engine

/// Automatically scores insight profundity based on multiple criteria
class InsightScoringEngine {
    
    /// Score a reasoning step for profundity
    static func scoreProfundity(
        step: ReasoningStep,
        in logicEntry: LogicEntry,
        against previousEntries: [LogicEntry] = []
    ) -> Double {
        
        guard step.type == .insight else { return 0.0 }
        
        var score = 0.0
        
        // Criterion 1: Does it trigger belief revision? (weight: 0.3)
        if triggersBeliefsChange(step: step, in: logicEntry) {
            score += 0.3
        }
        
        // Criterion 2: Does it connect multiple perspectives? (weight: 0.25)
        let connectionScore = scoreMultiPerspectiveConnection(step: step, in: logicEntry)
        score += connectionScore * 0.25
        
        // Criterion 3: Does it resolve tension? (weight: 0.2)
        if resolvesOscillation(step: step, in: logicEntry) {
            score += 0.2
        }
        
        // Criterion 4: Is it novel/new? (weight: 0.15)
        let noveltyScore = computeNovelty(of: step, against: previousEntries)
        score += min(noveltyScore, 1.0) * 0.15
        
        // Criterion 5: Was it user-flagged as important? (weight: 0.1)
        if step.userFlagged ?? false {
            score += 0.1
        }
        
        return min(1.0, score)
    }
    
    /// Check if this insight triggers belief changes
    private static func triggersBeliefsChange(step: ReasoningStep, in logicEntry: LogicEntry) -> Bool {
        // If the final response mentions this insight, likely influenced thinking
        let response = logicEntry.finalResponse.lowercased()
        let stepContent = step.content.lowercased()
        
        // Check for key threshold keywords
        let triggeringPhrases = ["therefore", "thus", "means", "implies", "changes how",
                                "reconsider", "actually", "instead", "better", "important"]
        
        let hasTriggeringPhrase = triggeringPhrases.contains { 
            response.contains($0) && response.contains(String(stepContent.prefix(10)))
        }
        
        return hasTriggeringPhrase
    }
    
    /// Score how many perspectives this insight connects
    private static func scoreMultiPerspectiveConnection(
        step: ReasoningStep,
        in logicEntry: LogicEntry
    ) -> Double {
        let stepContent = step.content.lowercased()
        
        var connectedCount = 0
        for perspective in logicEntry.perspectives {
            let reasoning = perspective.reasoning.lowercased()
            // Simple similarity check: shared key words
            let words = stepContent.split(separator: " ").map { String($0) }
            let connectionCount = words.filter { reasoning.contains($0) }.count
            if connectionCount >= 2 {
                connectedCount += 1
            }
        }
        
        // Score: 1.0 if 2+ perspectives connected
        return connectedCount >= 2 ? 1.0 : Double(connectedCount) * 0.5
    }
    
    /// Check if this insight resolves a belief oscillation
    private static func resolvesOscillation(
        step: ReasoningStep,
        in logicEntry: LogicEntry
    ) -> Bool {
        // In future: check if any belief that was oscillating is now stable
        // For now: check if insight content suggests resolution
        let resolutionKeywords = ["balance", "both", "integrate", "holistic", "together",
                                 "resolve", "solution", "reconcile"]
        
        let content = step.content.lowercased()
        return resolutionKeywords.contains { content.contains($0) }
    }
    
    /// Compute how novel this insight is
    private static func computeNovelty(
        of step: ReasoningStep,
        against previousEntries: [LogicEntry]
    ) -> Double {
        guard !previousEntries.isEmpty else { return 0.7 } // Default novelty
        
        let stepContent = step.content.lowercased()
        let stepWords = Set(stepContent.split(separator: " ").map { String($0) })
        
        var similarityScores: [Double] = []
        
        for entry in previousEntries {
            let insightSteps = entry.reasoningSteps.filter { $0.type == .insight }
            for insight in insightSteps {
                let insightWords = Set(insight.content.lowercased().split(separator: " ").map { String($0) })
                
                // Jaccard similarity
                let intersection = stepWords.intersection(insightWords).count
                let union = stepWords.union(insightWords).count
                let similarity = union > 0 ? Double(intersection) / Double(union) : 0.0
                similarityScores.append(similarity)
            }
        }
        
        // Novelty = 1 - average similarity
        let avgSimilarity = similarityScores.isEmpty ? 0.0 : similarityScores.reduce(0, +) / Double(similarityScores.count)
        return max(0.0, 1.0 - avgSimilarity)
    }
    
    /// Identify all profound insights in a logic entry
    static func identifyProfoundInsights(
        in logicEntry: LogicEntry,
        againstHistory previousEntries: [LogicEntry] = []
    ) -> [ReasoningStep] {
        
        let insightSteps = logicEntry.reasoningSteps.filter { $0.type == .insight }
        
        // Score all insights
        let scored = insightSteps.map { insight -> (ReasoningStep, Double) in
            let score = scoreProfundity(step: insight, in: logicEntry, against: previousEntries)
            return (insight, score)
        }
        
        // Threshold: top 20% or score >= 0.6, whichever is lower threshold
        let threshold = max(0.6, scored.sorted { $0.1 < $1.1 }.dropFirst(Int(Double(scored.count) * 0.8)).first?.1 ?? 0.5)
        
        return scored.filter { $0.1 >= threshold }.map { $0.0 }
    }
    
    /// Mark profound insights in a logic entry
    static func markProfoundInsights(in logicEntry: inout LogicEntry) {
        let profound = identifyProfoundInsights(in: logicEntry)
        
        for i in logicEntry.reasoningSteps.indices {
            if profound.contains(where: { $0.id == logicEntry.reasoningSteps[i].id }) {
                logicEntry.reasoningSteps[i].isProfound = true
            }
        }
    }
}

// MARK: - ReasoningStep Extension

extension ReasoningStep {
    var isProfound: Bool {
        get { userFlagged ?? false } // Repurpose or add separate property
        set { userFlagged = newValue }
    }
    
    /// Human-readable scoring explanation
    func explanationOfProfundity() -> String {
        let score = userFlagged ?? false ? "High" : "Standard"
        return "\(score) profundity insight - meaningful contribution to reasoning"
    }
}
