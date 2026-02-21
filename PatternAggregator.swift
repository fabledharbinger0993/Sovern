import Foundation

// MARK: - Pattern Analysis

struct PatternAnalysis {
    let pattern: String
    let frequency: Int
    let confidenceScore: Double        // 0-1
    let sourceInsights: [Insight]
    let suggestedCategory: PatternCategory
    let needsUserConfirmation: Bool
}

enum PatternCategory: String, CaseIterable {
    case userValue           = "User Value"
    case userKnowledgeGap    = "Knowledge Gap"
    case userReasoningStyle  = "Reasoning Style"
    case sovernLimitation    = "Sovern Limitation"
    case sovernStrength      = "Sovern Strength"
    case conversationDynamic = "Conversation Dynamics"
}

// MARK: - Pattern Aggregator

/// Aggregates and categorizes patterns from memory entries
class PatternAggregator: ObservableObject {
    
    @Published var identifiedPatterns: [PatternAnalysis] = []
    @Published var pendingPatterns: [PatternAnalysis] = []
    
    /// Aggregate patterns from all memories
    func aggregatePatterns(from memories: [MemoryEntry]) -> [PatternAnalysis] {
        var patternMap: [String: [Insight]] = [:]
        
        // 1. Collect all insights
        for memory in memories {
            for insight in memory.humanInsights {
                let key = normalize(insight.content)
                patternMap[key, default: []].append(insight)
            }
            
            for insight in memory.selfInsights {
                let key = normalize(insight.content)
                patternMap[key, default: []].append(insight)
            }
        }
        
        // 2. Score patterns by frequency + coherence
        var allPatterns: [PatternAnalysis] = []
        
        for (patternText, insights) in patternMap {
            let frequency = insights.count
            
            // Threshold: must appear 2+ times to be a pattern
            guard frequency >= 2 else { continue }
            
            // Confidence = frequency / total interactions
            let confidence = Double(frequency) / Double(memories.count)
            let needsConfirmation = confidence < 0.6  // Low confidence needs verification
            
            let analysis = PatternAnalysis(
                pattern: patternText,
                frequency: frequency,
                confidenceScore: confidence,
                sourceInsights: insights,
                suggestedCategory: categorizePattern(patternText),
                needsUserConfirmation: needsConfirmation
            )
            
            allPatterns.append(analysis)
        }
        
        // 3. Sort by frequency (descending)
        allPatterns.sort { $0.frequency > $1.frequency }
        
        // 4. Separate high and low confidence
        self.identifiedPatterns = allPatterns.filter { !$0.needsUserConfirmation }
        self.pendingPatterns = allPatterns.filter { $0.needsUserConfirmation }
        
        return allPatterns
    }
    
    /// User confirms a pattern as accurate
    func confirmPattern(_ pattern: PatternAnalysis) {
        pendingPatterns.removeAll { $0.pattern == pattern.pattern }
        if !identifiedPatterns.contains(where: { $0.pattern == pattern.pattern }) {
            identifiedPatterns.append(pattern)
        }
    }
    
    /// User rejects a pattern
    func rejectPattern(_ pattern: PatternAnalysis) {
        pendingPatterns.removeAll { $0.pattern == pattern.pattern }
    }
    
    /// Get patterns by category
    func patterns(for category: PatternCategory) -> [PatternAnalysis] {
        return identifiedPatterns.filter { $0.suggestedCategory == category }
    }
    
    /// Normalize text for pattern comparison
    private func normalize(_ text: String) -> String {
        var result = text.lowercased()
        
        // Remove articles
        result = result.replacingOccurrences(of: " the ", with: " ")
        result = result.replacingOccurrences(of: " a ", with: " ")
        result = result.replacingOccurrences(of: " an ", with: " ")
        
        // Remove extra whitespace
        result = result.trimmingCharacters(in: .whitespaces)
        
        return result
    }
    
    /// Categorize a pattern
    private func categorizePattern(_ text: String) -> PatternCategory {
        let lowerText = text.lowercased()
        
        if lowerText.contains("value") || lowerText.contains("care") || 
           lowerText.contains("priorit") || lowerText.contains("important") {
            return .userValue
        } else if lowerText.contains("don't know") || lowerText.contains("unclear") ||
                  lowerText.contains("gap") || lowerText.contains("struggling") {
            return .userKnowledgeGap
        } else if lowerText.contains("reason") || lowerText.contains("think") ||
                  lowerText.contains("approach") || lowerText.contains("tend") {
            return .userReasoningStyle
        } else if lowerText.contains("struggle") || lowerText.contains("hard") ||
                  lowerText.contains("limit") || lowerText.contains("challenge") {
            return .sovernLimitation
        } else if lowerText.contains("strength") || lowerText.contains("good") ||
                  lowerText.contains("excel") || lowerText.contains("well") {
            return .sovernStrength
        } else {
            return .conversationDynamic
        }
    }
    
    /// Reset patterns
    func reset() {
        identifiedPatterns = []
        pendingPatterns = []
    }
}

// MARK: - Display Helpers

extension PatternAnalysis {
    /// Human-readable frequency description
    var frequencyDescription: String {
        switch frequency {
        case 2...3: return "Mentioned a few times"
        case 4...6: return "Mentioned several times"
        case 7...10: return "Mentioned frequently"
        default: return "Mentioned \(frequency) times"
        }
    }
    
    /// Confidence badge
    var confidenceBadge: String {
        switch confidenceScore {
        case 0.8...: return "High confidence ✅"
        case 0.6..<0.8: return "Medium confidence ⓘ"
        default: return "Lower confidence ?"
        }
    }
}
