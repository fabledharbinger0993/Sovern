import Foundation

// MARK: - Emergent Belief Candidate

struct EmergentBeliefCandidate {
    let stance: String
    let domain: BeliefDomain
    let supportingInsights: [Insight]
    let strength: Double          // 0-1 confidence
    let emergedFromLogicId: UUID
    let timestamp: Date
    let reasonToCreate: String
    
    /// Convert to a new BeliefNode
    func toBeliefNode() -> BeliefNode {
        let weight = max(1.0, strength * 5.0 + 2.0) // Scale to 1-10 range
        return BeliefNode(
            stance: stance,
            domain: domain,
            weight: weight,
            reasoning: reasonToCreate,
            isCore: false // Always learned
        )
    }
}

// MARK: - Belief Emergence Monitor

/// Monitors for patterns that suggest new belief emergence
class BeliefEmergenceMonitor: ObservableObject {
    
    @Published var candidatesDetected: [EmergentBeliefCandidate] = []
    
    /// Scan a logic entry for emergent belief patterns
    func scanForEmergentBeliefs(
        from logicEntry: LogicEntry,
        againstExisting beliefs: [BeliefNode],
        withHistory previousMemories: [MemoryEntry] = []
    ) -> [EmergentBeliefCandidate] {
        
        var candidates: [EmergentBeliefCandidate] = []
        
        // Extract novel concepts from reasoning steps
        let novelConcepts = extractNovelConcepts(from: logicEntry.reasoningSteps)
        
        for concept in novelConcepts {
            // Check if concept already exists as belief
            let alreadyExists = beliefs.contains { belief in
                belief.stance.lowercased().contains(concept.lowercased()) ||
                concept.lowercased().contains(belief.stance.lowercased())
            }
            
            if !alreadyExists {
                // Analyze this concept as potential belief
                let candidate = analyzeEmergentBelief(
                    concept: concept,
                    from: logicEntry,
                    previousMemories: previousMemories
                )
                
                // Only include if meets confidence threshold (0.7)
                if candidate.strength >= 0.7 {
                    candidates.append(candidate)
                }
            }
        }
        
        return candidates
    }
    
    /// Analyze a concept to see if it's ready to become a belief
    private func analyzeEmergentBelief(
        concept: String,
        from logicEntry: LogicEntry,
        previousMemories: [MemoryEntry]
    ) -> EmergentBeliefCandidate {
        
        // 1. Find related insights from this interaction
        let relatedInsights = logicEntry.reasoningSteps
            .filter { $0.type == .insight && $0.content.lowercased().contains(concept.lowercased()) }
            .compactMap { step -> Insight? in
                return Insight(
                    content: step.content,
                    category: .reasoningPattern,
                    source: "Logic entry \(logicEntry.userQuery)"
                )
            }
        
        // 2. Find related insights from previous memories
        let historicalInsights = previousMemories
            .flatMap { $0.selfInsights + $0.humanInsights }
            .filter { $0.content.lowercased().contains(concept.lowercased()) }
            .prefix(3) // Limit to 3
        
        let allInsights = relatedInsights + Array(historicalInsights)
        
        // 3. Determine domain fit
        let domain = inferDomain(of: concept, from: logicEntry.perspectives)
        
        // 4. Calculate confidence
        // Formula: (supporting_insights / 3) * 0.5 + 0.5 if related to multiple perspectives
        let perspectiveConnections = logicEntry.perspectives.filter { perspective in
            allInsights.contains { insight in
                insight.content.lowercased().contains(perspective.reasoning.prefix(20).lowercased())
            }
        }.count
        
        let insightScore = min(1.0, Double(allInsights.count) / 3.0)
        let perspectiveScore = min(1.0, Double(perspectiveConnections) / 2.0)
        let strength = (insightScore * 0.6) + (perspectiveScore * 0.4)
        
        return EmergentBeliefCandidate(
            stance: concept,
            domain: domain,
            supportingInsights: allInsights,
            strength: strength,
            emergedFromLogicId: logicEntry.id,
            timestamp: Date(),
            reasonToCreate: "Emerged from \(allInsights.count) supporting insights across reasoning pattern '\(concept)'"
        )
    }
    
    /// Extract novel concepts from reasoning steps
    private func extractNovelConcepts(from steps: [ReasoningStep]) -> [String] {
        let insightText = steps
            .filter { $0.type == .insight }
            .map { $0.content }
            .joined(separator: " ")
        
        // Extract capitalized phrases as potential concepts
        var concepts: [String] = []
        let words = insightText.split(separator: " ")
        
        for (index, word) in words.enumerated() {
            let wordStr = String(word).trimmingCharacters(in: .punctuationCharacters)
            
            // Look for capitalized words (potential proper nouns/concepts)
            if wordStr.first?.isUppercase ?? false && wordStr.count > 3 {
                // Combine with next word if it's also capitalized
                if index + 1 < words.count {
                    let nextWord = String(words[index + 1]).trimmingCharacters(in: .punctuationCharacters)
                    if nextWord.first?.isUppercase ?? false {
                        let combined = "\(wordStr) \(nextWord)"
                        if !concepts.contains(combined) && combined.count > 5 {
                            concepts.append(combined)
                        }
                        continue
                    }
                }
                
                if !concepts.contains(wordStr) {
                    concepts.append(wordStr)
                }
            }
        }
        
        // Fallback: extract key abstract nouns if no concepts found
        if concepts.isEmpty {
            let abstractNouns = ["Decision", "Learning", "Understanding", "Balance", "Context",
                                "Pattern", "Tension", "Growth", "Trust", "Change"]
            for noun in abstractNouns {
                if insightText.lowercased().contains(noun.lowercased()) {
                    concepts.append(noun)
                }
            }
        }
        
        return Array(Set(concepts)) // Deduplicate
    }
    
    /// Infer the best domain for a concept
    private func inferDomain(of concept: String, from perspectives: [CongressPerspective]) -> BeliefDomain {
        let concept = concept.lowercased()
        
        // Pattern-based inference
        if concept.contains("method") || concept.contains("process") || concept.contains("how") {
            return .knowledge
        } else if concept.contains("value") || concept.contains("right") || concept.contains("wrong") ||
                  concept.contains("good") || concept.contains("bad") {
            return .ethics
        } else if concept.contains("self") || concept.contains("identity") || concept.contains("ego") ||
                  concept.contains("authentic") {
            return .self
        } else if concept.contains("people") || concept.contains("relation") || concept.contains("connect") ||
                  concept.contains("empathy") {
            return .relational
        } else {
            return .meta // Default to metacognitive
        }
    }
    
    /// Check if a candidate should be created and return memory note if so
    func shouldCreateBelief(_ candidate: EmergentBeliefCandidate) -> Bool {
        return candidate.strength >= 0.7
    }
    
    /// Reset tracking
    func reset() {
        candidatesDetected = []
    }
}
