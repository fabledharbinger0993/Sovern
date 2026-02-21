import Foundation

// MARK: - RelationalMemory Sync Extension

extension RelationalMemory {
    
    /// Sync a MemoryEntry after interaction reflection is complete
    /// Called after humanInsights, selfInsights, and learnedPatterns are extracted
    func syncMemoryEntry(
        _ entry: MemoryEntry,
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        // Attempt to sync; on conflict (409) try to fetch remote, merge, and retry
        apiManager.syncMemoryEntry(entry) { [weak self] result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                // If offline, APIManager will have queued the item already — propagate offline
                if case .offline = error {
                    completion(.failure(.offline))
                    return
                }

                // If server returned a conflict, try to resolve by fetching remote and merging
                if case .serverError(let statusCode, _) = error, statusCode == 409 {
                    // Try to fetch remote entry and merge
                    apiManager.fetchMemoryEntry(id: entry.id) { fetchResult in
                        switch fetchResult {
                        case .success(let remoteRequest):
                            guard let self = self else {
                                completion(.failure(.unknown))
                                return
                            }

                            let merged = self.mergeMemoryEntry(local: entry, remote: remoteRequest)

                            // Retry sync with merged entry
                            apiManager.syncMemoryEntry(merged) { retryResult in
                                completion(retryResult)
                            }
                        case .failure:
                            // Could not fetch remote; propagate original error
                            completion(.failure(error))
                        }
                    }
                    return
                }

                // Other errors, propagate
                completion(.failure(error))
            }
        }
    }
    
    /// Sync ego state (self-insights) separately after reflection
    /// Called when self-reflection analysis completes
    func syncEgoState(
        from entry: MemoryEntry,
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let selfInsights = entry.selfInsights.insights
        let reasoningPatterns = extractReasoningPatterns(from: entry)
        let beliefAlignments = extractBeliefAlignments(from: entry)
        
        apiManager.syncEgoState(
            selfInsights: selfInsights,
            reasoningPatterns: reasoningPatterns,
            beliefAlignments: beliefAlignments,
            completion: completion
        )
    }
    
    /// Extract reasoning patterns from a memory entry
    /// Analyzes how Sovern tends to think
    private func extractReasoningPatterns(from entry: MemoryEntry) -> [String] {
        var patterns: [String] = []
        
        // Analyze self-insights for patterns
        let categories = Dictionary(groupingBy: entry.selfInsights.insights, by: { $0.category })
        
        if !categories[.reasoningPattern]?.isEmpty ?? false {
            patterns.append("Identifiable reasoning tendencies")
        }
        
        if !categories[.beliefAlignment]?.isEmpty ?? false {
            patterns.append("Belief-driven reasoning")
        }
        
        if !categories[.growthArea]?.isEmpty ?? false {
            patterns.append("Self-aware of growth areas")
        }
        
        // Add paradigm-based patterns
        patterns.append("Uses \(entry.paradigmRouting) paradigm")
        
        if entry.congressEngaged {
            patterns.append("Engages multi-perspective deliberation")
        }
        
        return patterns
    }
    
    /// Extract belief alignments from memory entry
    /// Returns (belief_stance, alignment_score, change_vector) tuples
    private func extractBeliefAlignments(from entry: MemoryEntry) -> [(stance: String, score: Double, vector: String)] {
        var alignments: [(stance: String, score: Double, vector: String)] = []
        
        // Analyze which beliefs were reinforced or challenged in this interaction
        for insight in entry.selfInsights.insights where insight.relatedBeliefId != nil {
            let category = insight.category
            
            // Infer alignment based on category
            let score: Double
            let vector: String
            
            switch category {
            case .beliefAlignment:
                score = 0.8
                vector = "strengthened"
            case .growthArea:
                score = -0.3  // Negative indicates area for growth (challenge)
                vector = "challenged"
            case .strengthIdentified:
                score = 0.9
                vector = "strengthened"
            default:
                score = 0.5
                vector = "neutral"
            }
            
            // Use generic belief name if relatedBeliefId not available
            alignments.append((
                stance: insight.content.prefix(30).trimmingCharacters(in: .whitespaces),
                score: score,
                vector: vector
            ))
        }
        
        return alignments
    }

    /// Merge a local MemoryEntry with a remote MemoryEntryRequest (from server)
    /// Strategy: preserve newest timestamp, union unique insights, and combine patterns/sources.
    private func mergeMemoryEntry(local: MemoryEntry, remote: MemoryEntryRequest) -> MemoryEntry {
        var merged = local

        // Prefer the most recent timestamp
        let remoteTimestamp = remote.timestamp
        if remoteTimestamp > merged.timestamp {
            // Update timestamp and top-level fields if remote is newer
            merged.setResearchNotes(remote.researchNotes)
        }

        // Merge human insights (add remote ones not present locally by content)
        for hi in remote.humanInsights {
            let exists = merged.humanInsights.insights.contains { $0.content == hi.content }
            if !exists {
                let newInsight = Insight(
                    content: hi.content,
                    category: InsightCategory(rawValue: hi.category) ?? .valueSignal,
                    relatedBeliefId: nil,
                    source: hi.source,
                    timestamp: Date()
                )
                merged.addHumanInsight(newInsight)
            }
        }

        // Merge self insights
        for si in remote.selfInsights {
            let exists = merged.selfInsights.insights.contains { $0.content == si.content }
            if !exists {
                let newInsight = Insight(
                    content: si.content,
                    category: InsightCategory(rawValue: si.category) ?? .reasoningPattern,
                    relatedBeliefId: nil,
                    source: nil,
                    timestamp: Date()
                )
                merged.addSelfInsight(newInsight)
            }
        }

        // Merge learned patterns: add simple synthesized LearnedPattern entries
        for pattern in remote.learnedPatterns {
            let exists = merged.learnedPatterns.contains { $0.pattern == pattern.pattern }
            if !exists {
                let lp = LearnedPattern(
                    pattern: pattern.pattern,
                    description: pattern.description,
                    evidence: pattern.evidence,
                    frequency: pattern.frequency,
                    relatedBeliefs: [],
                    discoveredAt: Date()
                )
                merged.addLearnedPattern(lp)
            }
        }

        // Note: do not overwrite dataSourcesAccessed here to avoid losing local provenance

        return merged
    }
    
    /// Create a summary report of learning for sync
    /// Returns aggregated insights and patterns for backend analysis
    func createLearningSummaryForSync() -> [String: Any] {
        return [
            "total_interactions": entries.count,
            "human_insights_count": allHumanInsights.count,
            "self_insights_count": allSelfInsights.count,
            "patterns_discovered": allLearnedPatterns.count,
            "human_insight_categories": categoryCounts(for: allHumanInsights),
            "self_insight_categories": categoryCounts(for: allSelfInsights),
            "most_common_paradigms": mostCommonParadigms(),
            "congress_engagement_rate": congressEngagementRate(),
            "average_learning_richness": averageLearningRichness()
        ]
    }
    
    /// Count insights by category
    private func categoryCounts(for insights: [Insight]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for insight in insights {
            let category = insight.category.rawValue
            counts[category, default: 0] += 1
        }
        return counts
    }
    
    /// Most frequently used paradigms
    private func mostCommonParadigms() -> [String: Int] {
        var paradigmCounts: [String: Int] = [:]
        for entry in entries {
            paradigmCounts[entry.paradigmRouting, default: 0] += 1
        }
        return paradigmCounts
    }
    
    /// Rate of Congress engagement (0-1)
    private func congressEngagementRate() -> Double {
        guard !entries.isEmpty else { return 0 }
        let engagedCount = entries.filter { $0.congressEngaged }.count
        return Double(engagedCount) / Double(entries.count)
    }
    
    /// Average learning richness (how many insight categories per entry)
    private func averageLearningRichness() -> Double {
        guard !entries.isEmpty else { return 0 }
        let totalRichness = entries.reduce(0) { total, entry in
            let humanCategories = Set(entry.humanInsights.insights.map { $0.category })
            let selfCategories = Set(entry.selfInsights.insights.map { $0.category })
            return total + humanCategories.count + selfCategories.count
        }
        return Double(totalRichness) / Double(entries.count)
    }
    
    /// Export all memory entries for batch sync (useful for offline recovery)
    func exportMemoryEntriesForSync() -> [[String: String]] {
        return entries.map { entry in
            [
                "id": entry.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: entry.timestamp),
                "user_query": entry.userQuery.prefix(100).description,
                "paradigm_routing": entry.paradigmRouting,
                "congress_engaged": String(entry.congressEngaged),
                "human_insights": String(entry.humanInsights.count),
                "self_insights": String(entry.selfInsights.count),
                "patterns": String(entry.learnedPatterns.count),
                "was_reflective": String(entry.wasSelfReflective),
                "learning_rich": String(entry.wasLearningRich)
            ]
        }
    }
}
