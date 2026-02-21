import Foundation

// MARK: - LogicLibrary Sync Extension

extension LogicLibrary {
    
    /// Sync a LogicEntry and its Congress debate to backend
    /// Called immediately after Congress deliberation completes
    func syncLogicEntry(
        _ entry: LogicEntry,
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        apiManager.syncLogicEntry(entry, completion: completion)
    }
    
    /// Sync Congress engagement state during deliberation
    /// Can be called mid-debate to track Congress engagement real-time
    func syncCongressEngagement(
        entryId: UUID,
        perspectives: [CongressPerspective],
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        apiManager.syncCongressState(
            congressEngaged: !perspectives.isEmpty,
            perspectives: perspectives,
            completion: completion
        )
    }
    
    /// Sync reasoning steps and candidate responses as they're generated
    /// Enables real-time tracking of reasoning progression
    func syncReasoningTimeline(
        entryId: UUID,
        withSteps steps: [ReasoningStep],
        candidateResponses: [CandidateResponse],
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let entry = entry(withId: entryId) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        // Create a detailed sync about the reasoning progression
        let stepRequests = steps.map { step in
            ReasoningStepRequest(
                stepType: step.type.rawValue,
                content: step.content,
                timestamp: step.timestamp
            )
        }
        
        let responseRequests = candidateResponses.map { response in
            CandidateResponseRequest(
                draftNumber: response.draftNumber,
                content: response.content,
                status: response.status.rawValue,
                rejectionReason: response.rejectionReason
            )
        }
        
        // Sync as part of logic entry update
        let request = LogicEntryRequest(
            sessionId: UUID().uuidString,
            userQuery: entry.userQuery,
            weight: entry.weight,
            paradigmRouting: entry.paradigmRouting,
            congressEngaged: entry.congressEngaged,
            perspectives: entry.perspectives.map { p in
                PerspectiveStateRequest(
                    role: p.role.rawValue,
                    position: p.position,
                    reasoning: p.reasoning,
                    strengthOfArgument: p.strengthOfArgument,
                    callNumber: p.callNumber
                )
            },
            reasoningSteps: stepRequests,
            candidateResponses: responseRequests,
            profoundInsights: entry.profoundInsights,
            finalResponse: entry.finalResponse,
            timestamp: entry.timestamp
        )
        
        // Use generic sync via APIManager
        apiManager.syncLogicEntry(entry, completion: completion)
    }
    
    /// Extract insights from Congress debate for ego state sync
    /// Returns self-insights discovered through reasoning
    func extractSelfInsights(from entryId: UUID) -> [Insight] {
        guard let entry = entry(withId: entryId) else { return [] }
        
        var insights: [Insight] = []
        
        // Analyze which perspectives dominated
        let roleFrequency = Dictionary(groupingBy: entry.perspectives, by: { $0.role })
        if let advocateCount = roleFrequency[.advocate]?.count, advocateCount > 2 {
            insights.append(Insight(
                content: "Tendency toward advocative reasoning in complex scenarios",
                category: .reasoningPattern,
                source: "Congress debate analysis"
            ))
        }
        
        if let skepticCount = roleFrequency[.skeptic]?.count, skepticCount > 2 {
            insights.append(Insight(
                content: "Strong skeptical analysis present in reasoning",
                category: .reasoningPattern,
                source: "Congress debate analysis"
            ))
        }
        
        // Analyze reasoning step patterns
        let stepTypes = Dictionary(groupingBy: entry.reasoningSteps, by: { $0.type })
        if let insightCount = stepTypes[.insight]?.count, insightCount > 0 {
            insights.append(Insight(
                content: "Capable of deriving novel insights (\(insightCount) insights generated)",
                category: .strengthIdentified,
                source: "Reasoning step analysis"
            ))
        }
        
        if let revisionCount = stepTypes[.revision]?.count, revisionCount > 0 {
            insights.append(Insight(
                content: "Demonstrates reflective reasoning by revising initial positions",
                category: .reasoningPattern,
                source: "Revision tracking"
            ))
        }
        
        // Analyze candidate response iterations
        let selectedResponse = entry.candidateResponses.first { $0.status == .selected }
        let rejectedCount = entry.candidateResponses.filter { $0.status == .rejected }.count
        
        if rejectedCount > 1 {
            insights.append(Insight(
                content: "Iterative refinement: \(rejectedCount) drafts rejected before final response",
                category: .reasoningPattern,
                source: "Response iteration analysis"
            ))
        }
        
        return insights
    }
    
    /// Export all logic entries for batch sync (useful for offline recovery)
    func exportLogicEntriesForSync() -> [[String: String]] {
        return entries.map { entry in
            [
                "id": entry.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: entry.timestamp),
                "user_query": entry.userQuery,
                "weight": String(entry.weight),
                "paradigm_routing": entry.paradigmRouting,
                "congress_engaged": String(entry.congressEngaged),
                "perspective_count": String(entry.perspectives.count),
                "reasoning_steps": String(entry.reasoningSteps.count),
                "candidate_responses": String(entry.candidateResponses.count),
                "profound_insights": String(entry.profoundInsights.count)
            ]
        }
    }
}
