import Foundation

// MARK: - BeliefSystem Sync Extension

extension BeliefSystem {
    
    /// Sync a belief update after weight change
    /// Called whenever challenge(), strengthen(), weaken(), or revise() is executed
    func syncBeliefUpdate(
        beliefId: UUID,
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let belief = belief(withId: beliefId) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        // Extract the most recent revision for sync
        guard let latestRevision = belief.revisionHistory.last else {
            // No revision history yet (shouldn't happen)
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        apiManager.syncBeliefUpdate(
            stance: belief.stance,
            domain: belief.domain.rawValue,
            weight: belief.weight,
            reasoning: belief.reasoning,
            revisionType: latestRevision.type.rawValue,
            revisionReason: latestRevision.reason,
            completion: completion
        )
    }
    
    /// Sync all core beliefs on app initialization
    /// Ensures backend has current canonical belief set
    func syncCoreBeliefs(
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let coreBeliefs = self.coreBeliefs
        
        // Sync each core belief sequentially
        syncBeliefSequence(coreBeliefs, using: apiManager, completion: completion)
    }
    
    /// Sync belief network coherence state
    /// Called periodically or after significant changes
    func syncNetworkCoherence(
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let coherenceMetadata: [String: String] = [
            "coherence_score": String(format: "%.1f", coherenceScore),
            "average_weight": String(format: "%.1f", averageWeight),
            "domain_balance": String(format: "%.1f", domainBalance),
            "total_revisions": String(totalRevisions),
            "total_beliefs": String(nodes.count),
            "core_beliefs": String(coreBeliefs.count),
            "learned_beliefs": String(learnedBeliefs.count)
        ]
        
        apiManager.syncParadigmState(
            queryType: "belief_coherence",
            metadata: coherenceMetadata,
            completion: completion
        )
    }
    
    /// Sync belief connections/relationships
    /// Ensures backend understands belief network topology
    func syncBeliefConnections(
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        var connectionData: [[String: String]] = []
        
        for belief in nodes {
            for connectionId in belief.connectionIds {
                if let connected = belief(withId: connectionId) {
                    connectionData.append([
                        "belief_from": belief.stance,
                        "belief_to": connected.stance,
                        "domain_from": belief.domain.rawValue,
                        "domain_to": connected.domain.rawValue
                    ])
                }
            }
        }
        
        let metadata: [String: String] = [
            "connection_count": String(connectionData.count),
            "network_density": String(format: "%.2f", networkDensity()),
            "connections_json": encodeConnectionsJSON(connectionData)
        ]
        
        apiManager.syncParadigmState(
            queryType: "belief_connections",
            metadata: metadata,
            completion: completion
        )
    }
    
    /// Detect volatile beliefs (frequently revised, conflicting)
    /// Returns beliefs that may need recalibration
    func detectVolatileBeliefsForSync() -> [(stance: String, volatility: Double)] {
        return volatileBeliefs.map { belief in
            let volatility = Double(belief.revisionHistory.count) / 10.0  // 0-1 scale
            return (stance: belief.stance, volatility: min(1.0, volatility))
        }
    }
    
    /// Create a belief system snapshot for backend storage
    /// Captures complete system state at a point in time
    func createBeliefSnapshotForSync() -> [String: Any] {
        return [
            "timestamp": Date(),
            "total_beliefs": nodes.count,
            "core_beliefs": coreBeliefs.count,
            "learned_beliefs": learnedBeliefs.count,
            "coherence_score": coherenceScore,
            "average_weight": averageWeight,
            "domain_balance": domainBalance,
            "total_revisions": totalRevisions,
            "beliefs": nodes.map { belief in
                [
                    "stance": belief.stance,
                    "domain": belief.domain.rawValue,
                    "weight": belief.weight,
                    "is_core": belief.isCore,
                    "revision_count": belief.revisionHistory.count,
                    "connections": belief.connectionIds.count
                ]
            },
            "domain_distribution": domainDistribution()
        ]
    }
    
    /// Get distribution of beliefs across domains
    private func domainDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        for belief in nodes {
            distribution[belief.domain.rawValue, default: 0] += 1
        }
        return distribution
    }
    
    /// Calculate network density (how interconnected beliefs are)
    private func networkDensity() -> Double {
        guard nodes.count > 1 else { return 0 }
        
        let maxConnections = nodes.count * (nodes.count - 1) / 2
        var actualConnections = 0
        
        var counted = Set<String>()
        for belief in nodes {
            for connectionId in belief.connectionIds {
                let pair = [belief.id.uuidString, connectionId.uuidString].sorted().joined(separator: "-")
                if !counted.contains(pair) {
                    actualConnections += 1
                    counted.insert(pair)
                }
            }
        }
        
        return Double(actualConnections) / Double(maxConnections)
    }
    
    /// Helper: Sync a sequence of beliefs
    private func syncBeliefSequence(
        _ beliefs: [BeliefNode],
        using apiManager: APIManager,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard !beliefs.isEmpty else {
            completion(.success(()))
            return
        }
        
        let belief = beliefs[0]
        let remaining = Array(beliefs.dropFirst())
        
        syncBeliefUpdate(beliefId: belief.id, using: apiManager) { result in
            switch result {
            case .success:
                // Continue with next belief
                self.syncBeliefSequence(remaining, using: apiManager, completion: completion)
            case .failure(let error):
                // Stop on first error
                completion(.failure(error))
            }
        }
    }
    
    /// Encode connections as JSON string for metadata
    private func encodeConnectionsJSON(_ connections: [[String: String]]) -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: connections),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
    
    /// Export belief system for full backup/sync
    func exportBeliefSystemForSync() -> [[String: String]] {
        return nodes.map { belief in
            [
                "id": belief.id.uuidString,
                "stance": belief.stance,
                "domain": belief.domain.rawValue,
                "weight": String(belief.weight),
                "is_core": String(belief.isCore),
                "reasoning": belief.reasoning,
                "created_date": ISO8601DateFormatter().string(from: belief.createdDate),
                "last_updated": ISO8601DateFormatter().string(from: belief.lastUpdated),
                "revision_count": String(belief.revisionHistory.count),
                "connections": String(belief.connectionIds.count)
            ]
        }
    }
}
