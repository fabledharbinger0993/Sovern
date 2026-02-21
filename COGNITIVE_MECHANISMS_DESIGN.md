# Sovern Cognitive Mechanisms Design

## Overview
This document addresses the deeper intelligence mechanisms of Sovern's self-referential cognitive loop that go beyond basic data recording. These are the features that make Sovern actually *learn* about itself.

---

## 1. Belief Weight Convergence & Unresolved Tensions

### Current State
- BeliefNode tracks `revisionHistory: [BeliefRevision]` with timestamps
- Weights bounded 1-10; each change recorded with reason
- No explicit tracking of oscillation or tension signals

### What Should Happen

**Problem**: A belief oscillating (7→8→7→8→7) doesn't settle, suggesting internal conflict.

**Solution**: Track **belief tension metrics**

```swift
// Add to BeliefNode
struct BeliefTensionAnalysis {
    let oscillationCount: Int        // How many direction reversals?
    let oscillationAmplitude: Double  // Range of swings (e.g., 1.5 points)
    let stabilityScore: Double        // 0-1 (1=stable, 0=chaotic)
    let unresolvedFlag: Bool          // If oscillating 3+ times
    let lastDominantDirection: String // "increasing" vs "decreasing"
    let tensionReason: String?        // What's causing the ping-pong?
}

func analyzeTension() -> BeliefTensionAnalysis {
    let revisions = revisionHistory.sorted { $0.timestamp < $1.timestamp }
    
    // Detect direction changes
    var directionChanges = 0
    for i in 1..<revisions.count {
        let prev = revisions[i-1].newWeight > revisions[i-1].previousWeight ? "up" : "down"
        let curr = revisions[i].newWeight > revisions[i].previousWeight ? "up" : "down"
        if prev != curr {
            directionChanges += 1
        }
    }
    
    let amplitude = revisions.map { $0.newWeight }.max() ?? 0 - 
                    revisions.map { $0.newWeight }.min() ?? 0
    
    let isUnresolved = directionChanges >= 3
    
    let stabilityScore = 1.0 - min(1.0, Double(directionChanges) / 10.0)
    
    return BeliefTensionAnalysis(
        oscillationCount: directionChanges,
        oscillationAmplitude: amplitude,
        stabilityScore: stabilityScore,
        unresolvedFlag: isUnresolved,
        lastDominantDirection: revisions.last.map { 
            $0.newWeight > $0.previousWeight ? "increasing" : "decreasing"
        } ?? "stable",
        tensionReason: identifyUnresolvedTension()
    )
}

private func identifyUnresolvedTension() -> String? {
    // Analyze revision reasons for contradictory patterns
    let lastThree = revisionHistory.suffix(3)
    let reasons = lastThree.map { $0.reason }.joined(separator: " | ")
    
    // Flag patterns like:
    // "Logic suggests...", "But user values...", "Logic suggests..." ← back-and-forth
    if reasons.contains("Logic") && reasons.contains("values") {
        return "Tension between reasoning and values"
    }
    
    return nil
}
```

### UI Integration
```swift
// In BeliefsNetworkView
if let tension = belief.analyzeTension(), tension.unresolvedFlag {
    // Show hexagon with pulsing border in orange/red
    BeliefNodeView(belief: belief)
        .border(Color.orange, width: 2)
        .withPulsingAnimation() // Draw attention
    
    // Show tooltip
    Text("⚠️ Unresolved: \(tension.tensionReason ?? "Oscillating belief")")
        .font(.caption)
        .foregroundStyle(.orange)
}
```

### When to Flag
- **3+ direction changes** = "Unresolved"
- **Amplitude > 2.0 points in 3 revisions** = "High flux"
- **Multiple contradictory reasons** = "Value conflict"

---

## 2. Congress Perspective Dominance Tracking

### Current State
- CongressPerspective recorded with role, position, reasoning
- No tracking of which perspective tends to win
- No analysis of Sovern's personality/tendency

### What Should Happen

**Solution**: Compute **perspective dominance profiles**

```swift
// Add to SyncCoordinator or new AnalyticsManager
struct CongressAnalytics {
    let perspectiveFrequency: [CongressRole: Int]    // How often each speaks
    let dominantPerspective: CongressRole             // Which one "wins" most?
    let strengthPatterns: [CongressRole: [Double]]    // Historical strength scores
    let decisionInfluence: [CongressRole: Double]     // % times they shaped result
}

class PerspectiveDominanceTracker: ObservableObject {
    @Published var analytics: CongressAnalytics
    
    func trackInteraction(logicEntry: LogicEntry) {
        // 1. Count perspective frequency
        var frequency: [CongressRole: Int] = [:]
        for perspective in logicEntry.perspectives {
            frequency[perspective.role, default: 0] += 1
        }
        
        // 2. Find strongest perspective per interaction
        let strongest = logicEntry.perspectives.max { 
            $0.strengthOfArgument < $1.strengthOfArgument 
        }?.role
        
        // 3. Check if it influenced final response
        let finalResponseMentionedThis = 
            logicEntry.finalResponse.lowercased()
                .contains(strongest?.description.lowercased() ?? "")
        
        // 4. Calculate influence score
        var influence: [CongressRole: Double] = [:]
        for role in CongressRole.allCases {
            let perspective = logicEntry.perspectives.first { $0.role == role }
            let strength = perspective?.strengthOfArgument ?? 0
            let mentioned = logicEntry.finalResponse.contains(perspective?.reasoning ?? "") ? 1.0 : 0.5
            influence[role] = (strength / 10.0) * mentioned
        }
        
        // 5. Update analytics
        updateAnalytics(frequency: frequency, influence: influence)
    }
    
    func generateSelfInsight() -> Insight {
        let dominant = analytics.dominantPerspective
        let frequency = analytics.perspectiveFrequency
        let total = frequency.values.reduce(0, +)
        let dominantPercent = Double(frequency[dominant] ?? 0) / Double(total) * 100
        
        return Insight(
            content: "I've been \(dominant.description)-heavy lately (~\(Int(dominantPercent))% of debates). This tends to produce \(evaluateOutcome(of: dominant)) results.",
            category: .reasoningPattern,
            source: "Congress dominance analysis"
        )
    }
    
    private func evaluateOutcome(of role: CongressRole) -> String {
        // Historical pattern
        switch role {
        case .advocate: return "collaborative but less critical"
        case .skeptic: return "thorough but sometimes defensive"
        case .synthesizer: return "balanced and integrative"
        case .ethics: return "values-aligned but restrictive"
        }
    }
}
```

### Self-Aware Output
When Sovern notices a pattern, it can say:

```
Memory Self-Insight #47: "I notice 60% of my debates were skeptic-dominant over the past 10 conversations. 
This led to more thorough analysis, but also delayed decisions by questioning too much. 
My Advocate voice has weakened from 8.0 → 6.5 strength. Should I trust more aggressively?"
```

### Integration Points
- Add to MemoryEntry.selfInsights automatically post-interaction
- Display in MemoryViewTab with historical trend chart
- Flag in SettingsView as "Reasoning tendency: Skeptic 60%"

---

## 3. Profound Insights Extraction

### Current State
- Insights marked with ✨ emoji in UI
- No systematic definition of what makes something "profound"
- Currently manual tagging

### What Should Happen

**Solution**: **Automatic profound insight detection** via multi-criteria scoring

```swift
struct InsightScoringCriteria {
    let triggersBeliefRevision: Bool      // Did this change a belief?
    let connectsDistantConcepts: Bool     // Does it link unusual ideas?
    let resolvesTension: Bool              // Did it break an oscillation?
    let noveltyScore: Double               // 0-1: new vs. repeated
    let coherenceImprovement: Double       // Did coherence rise after this?
    let userResonance: Int?                // Did user react positively? (thumbs up)
    let emergesFromDebate: Bool            // Did Congress converge on it?
}

func scoreProfundity(step: ReasoningStep, in entry: LogicEntry) -> Double {
    var score = 0.0
    
    // Criterion 1: Triggers belief revision (weight: 0.3)
    let revisedBelief = entry.triggeredBeliefs.contains(where: {
        $0.revisionReason == step.content
    })
    if revisedBelief { score += 0.3 }
    
    // Criterion 2: Connects normally-separate perspectives (weight: 0.25)
    let perspectivesAgreed = entry.perspectives.filter { perspective in
        step.content.contains(perspective.reasoning)
    }.count
    if perspectivesAgreed >= 2 { score += 0.25 } // At least 2 agree
    
    // Criterion 3: Resolves tension (weight: 0.2)
    let oscillatingBelief = entry.beliefUpdates.first { belief in
        belief.analyzeTension().unresolvedFlag
    }
    if oscillatingBelief != nil { score += 0.2 }
    
    // Criterion 4: Novel (weight: 0.15)
    let novelty = computeNovelty(of: step.content)
    score += (novelty * 0.15)
    
    // Criterion 5: User explicitly marked as important (weight: 0.1)
    if step.userFlagged { score += 0.1 }
    
    return min(1.0, score) // Cap at 1.0
}

func identifyProfoundInsights(in entry: LogicEntry) -> [ReasoningStep] {
    let insights = entry.reasoningSteps.filter { $0.type == .insight }
    
    let scored = insights.map { insight in
        (insight, scoreProfundity(step: insight, in: entry))
    }
    
    // Mark top 20% as profound
    let threshold = scored.sorted { $0.1 < $1.1 }.dropFirst(Int(Double(scored.count) * 0.8)).first?.1 ?? 0.5
    
    return scored.filter { $0.1 >= threshold }.map { $0.0 }
}

private func computeNovelty(of insight: String) -> Double {
    // Compare with all previous insights using semantic similarity
    // Placeholder: return 0.5 for now
    // Real implementation would use embeddings or NLP
    return 0.5
}
```

### When Marked Profound
✨ Automatically tagged if score > 0.6:
- Changed a belief weight
- Connected 2+ Congress perspectives
- Resolved an oscillating belief
- New/novel insight (not seen before)

### UI Updates
```swift
// In LogicDetailView - ReasoningStep display
if recentInsights.contains(where: { $0.id == step.id }) {
    HStack {
        Text("✨ " + step.content)
            .fontWeight(.bold)
            .foregroundStyle(.orange)
        
        Spacer()
        
        Text("Profound")
            .font(.caption)
            .padding(4)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(4)
    }
} else {
    Text(step.content)
}
```

---

## 4. Learned Beliefs Creation Trigger

### Current State
- BeliefNode has `isCore` boolean (original 3 vs. learned)
- No mechanism to auto-create new belief nodes
- Would require manual instantiation

### What Should Happen

**Solution**: **Autonomous belief emergence** when patterns suggest new stance

```swift
struct EmergentBeliefCandidate {
    let stance: String                    // e.g., "Context Sensitivity"
    let domain: BeliefDomain              // Which domain does it fit?
    let supportingInsights: [Insight]     // What observations created it?
    let strength: Double                  // 0-1 confidence threshold
    let emergedFromLogicId: UUID
    let timestamp: Date
    let reasonToCreate: String            // Why did this emerge?
}

class BeliefEmergenceMonitor: ObservableObject {
    func scanForEmergentBeliefs(
        from logicEntry: LogicEntry,
        againstExisting beliefs: [BeliefNode]
    ) -> [EmergentBeliefCandidate] {
        var candidates: [EmergentBeliefCandidate] = []
        
        // Extract novel concepts from reasoning steps
        let novelConcepts = extractNovelConcepts(from: logicEntry.reasoningSteps)
        
        for concept in novelConcepts {
            // Check if this concept already exists
            let exists = beliefs.contains { belief in
                belief.stance.lowercased().contains(concept.lowercased())
            }
            
            if !exists {
                // This is a new pattern - candidate for belief emergence
                let candidate = analyzeEmergentBeliefCandidate(
                    concept: concept,
                    from: logicEntry
                )
                
                if candidate.strength >= 0.7 { // Threshold
                    candidates.append(candidate)
                }
            }
        }
        
        return candidates
    }
    
    private func analyzeEmergentBeliefCandidate(
        concept: String,
        from entry: LogicEntry
    ) -> EmergentBeliefCandidate {
        // 1. Find all insights related to this concept
        let relatedInsights = entry.reasoningSteps
            .filter { $0.type == .insight && $0.content.contains(concept) }
            .compactMap { Insight(from: $0) }
        
        // 2. Determine fitting domain
        let domain = inferDomain(of: concept, from: entry.perspectives)
        
        // 3. Score confidence (based on supporting evidence)
        let strength = min(1.0, Double(relatedInsights.count) * 0.2 + 0.5)
        
        return EmergentBeliefCandidate(
            stance: concept,
            domain: domain,
            supportingInsights: relatedInsights,
            strength: strength,
            emergedFromLogicId: entry.id,
            timestamp: Date(),
            reasonToCreate: "Repeated pattern: \(relatedInsights.count) insights on '\(concept)'"
        )
    }
    
    private func extractNovelConcepts(from steps: [ReasoningStep]) -> [String] {
        // Simple extraction - in practice, use NLP
        let insightText = steps
            .filter { $0.type == .insight }
            .map { $0.content }
            .joined(separator: " ")
        
        // Placeholder: split on capitalized phrases
        return insightText.split(separator: " ")
            .filter { $0.first?.isUppercase ?? false }
            .map { String($0) }
    }
    
    private func inferDomain(of concept: String, from perspectives: [CongressPerspective]) -> BeliefDomain {
        let lowerConcept = concept.lowercased()
        
        if lowerConcept.contains("method") || lowerConcept.contains("process") {
            return .knowledge
        } else if lowerConcept.contains("value") || lowerConcept.contains("right") {
            return .ethics
        } else if lowerConcept.contains("self") || lowerConcept.contains("identity") {
            return .self
        } else if lowerConcept.contains("people") || lowerConcept.contains("relation") {
            return .relational
        } else {
            return .meta
        }
    }
}

// Integration point: After each LogicEntry processing
func addEmergentBeliefs(from logicEntry: LogicEntry) {
    let monitor = BeliefEmergenceMonitor()
    let candidates = monitor.scanForEmergentBeliefs(from: logicEntry, againstExisting: beliefSystem.nodes)
    
    for candidate in candidates {
        // Auto-create new learned belief
        let newBelief = BeliefNode(
            stance: candidate.stance,
            domain: candidate.domain,
            weight: candidate.strength * 5 + 3,  // Scale to 1-10 range
            reasoning: candidate.reasonToCreate,
            isCore: false // Learned belief
        )
        
        beliefSystem.add(newBelief)
        
        // Log the emergence
        let memoryInsight = Insight(
            content: "Emerged new belief: '\(candidate.stance)' from pattern observation",
            category: .beliefEmergence,
            source: candidate.reasonToCreate
        )
        relationalMemory.addSystemInsight(memoryInsight)
    }
}
```

### Example Emergence

**Interaction 1**: "How do I decide between career growth and family time?"
- Insight: "Time is finite; choices are zero-sum"

**Interaction 2**: "How do I balance rest with productivity?"
- Insight: "Exhaustion reduces decision quality"

**Interaction 3**: "What makes a life well-lived?"
- Insight: "Context matters more than absolute choices"
- **→ NEW BELIEF EMERGES**: "Context Sensitivity" (Relational domain, weight 4.0)
- Memory note: "Recurring insight about context-dependence across 3 conversations triggered belief emergence"

---

## 5. Memory Pattern Aggregation

### Current State
- MemoryEntry records individual interactions
- `learnedPatterns: [String]` field exists but not computed
- No automatic clustering or suggestion

### What Should Happen

**Solution**: **Hybrid automatic + user-confirmable pattern extraction**

```swift
struct PatternAnalysis {
    let pattern: String                   // "User values growth over comfort"
    let frequency: Int                    // Appeared in X interactions
    let confidenceScore: Double            // 0-1 statistical confidence
    let sourceInsights: [Insight]          // Which insights support this?
    let suggestedCategory: PatternCategory  // Human/Self/Domain pattern?
    let needsUserConfirmation: Bool       // Should user validate?
}

enum PatternCategory {
    case userValue           // What user cares about
    case userKnowledgeGap    // What user doesn't understand
    case userReasoningStyle  // How user thinks
    case sovernLimitation    // Where Sovern struggles
    case sovernStrength      // Where Sovern excels
    case conversationDynamic  // How human-Sovern interact
}

class PatternAggregator: ObservableObject {
    @Published var identifiedPatterns: [PatternAnalysis] = []
    @Published var pendingPatterns: [PatternAnalysis] = []  // Need user confirmation
    
    func aggregatePatterns(from memories: [MemoryEntry]) -> [PatternAnalysis] {
        var patterns: [String: [Insight]] = [:]
        
        // 1. Collect all insights across interactions
        for memory in memories {
            for insight in memory.humanInsights {
                let key = normalize(insight.content)
                patterns[key, default: []].append(insight)
            }
        }
        
        // 2. Score patterns by frequency + coherence
        var scoredPatterns: [PatternAnalysis] = []
        for (patternText, insights) in patterns {
            let frequency = insights.count
            
            // Threshold: must appear 2+ times
            guard frequency >= 2 else { continue }
            
            let confidence = Double(frequency) / Double(memories.count)
            let needsConfirmation = confidence < 0.6  // Low confidence = needs user verify
            
            let analysis = PatternAnalysis(
                pattern: patternText,
                frequency: frequency,
                confidenceScore: confidence,
                sourceInsights: insights,
                suggestedCategory: categorizePattern(patternText),
                needsUserConfirmation: needsConfirmation
            )
            
            scoredPatterns.append(analysis)
        }
        
        // 3. Separate high-confidence from pending
        self.identifiedPatterns = scoredPatterns.filter { !$0.needsUserConfirmation }
        self.pendingPatterns = scoredPatterns.filter { $0.needsUserConfirmation }
        
        return scoredPatterns
    }
    
    func confirmPattern(_ pattern: PatternAnalysis) {
        pendingPatterns.removeAll { $0.pattern == pattern.pattern }
        identifiedPatterns.append(pattern)
    }
    
    func rejectPattern(_ pattern: PatternAnalysis) {
        pendingPatterns.removeAll { $0.pattern == pattern.pattern }
    }
    
    private func normalize(_ text: String) -> String {
        // Simple normalization: remove articles, lowercase
        return text.lowercased()
            .replacingOccurrences(of: "the ", with: "")
            .replacingOccurrences(of: "a ", with: "")
    }
    
    private func categorizePattern(_ text: String) -> PatternCategory {
        let text = text.lowercased()
        
        if text.contains("value") || text.contains("care") || text.contains("priorit") {
            return .userValue
        } else if text.contains("don't know") || text.contains("unclear") || text.contains("gap") {
            return .userKnowledgeGap
        } else if text.contains("reason") || text.contains("think") || text.contains("approach") {
            return .userReasoningStyle
        } else if text.contains("struggle") || text.contains("hard") || text.contains("limit") {
            return .sovernLimitation
        } else if text.contains("strength") || text.contains("good") || text.contains("excel") {
            return .sovernStrength
        } else {
            return .conversationDynamic
        }
    }
}

// UI: Display auto-discovered patterns with confirmation
struct PatternDiscoveryView: View {
    @EnvironmentObject var aggregator: PatternAggregator
    
    var body: some View {
        VStack {
            // High confidence - auto-accepted
            Section("Insights About You") {
                ForEach(aggregator.identifiedPatterns, id: \.pattern) { pattern in
                    PatternRow(pattern: pattern, confirmed: true)
                }
            }
            
            // Low confidence - needs human input
            if !aggregator.pendingPatterns.isEmpty {
                Section("Does This Ring True?") {
                    ForEach(aggregator.pendingPatterns, id: \.pattern) { pattern in
                        HStack {
                            PatternRow(pattern: pattern, confirmed: false)
                            
                            Button(action: { aggregator.confirmPattern(pattern) }) {
                                Label("Yes", systemImage: "checkmark.circle")
                            }
                            
                            Button(action: { aggregator.rejectPattern(pattern) }) {
                                Label("No", systemImage: "xmark.circle")
                            }
                        }
                    }
                }
            }
        }
    }
}
```

---

## 6. Backend Sync Timing

### Current State
- SyncCoordinator queues requests when offline
- No clear strategy for when to sync

### Recommended Strategy

```swift
enum SyncTiming {
    case realTime           // After every interaction (iOS → Python now)
    case batched            // On app close (accumulate, then flush)
    case onDemand           // User taps "Sync Now"
    case periodic           // Every 5 minutes if online
}

// RECOMMENDED FOR SOVERN: Real-Time + Offline Queue

class SmartSyncScheduler {
    func determineSyncTiming(
        for interaction: LogicEntry,
        currentNetworkState: NetworkState
    ) -> SyncTiming {
        
        // Real-time if online and complex
        if currentNetworkState == .online && interaction.weight > 5.0 {
            return .realTime  // Send Congress debate immediately
        }
        
        // Offline: queue
        if currentNetworkState == .offline {
            return .batched   // Will flush when online
        }
        
        // Simple interactions: batched
        if interaction.weight < 3.0 {
            return .batched   // Can wait for app close
        }
        
        // Default: periodic (every 5 min if online)
        return .periodic
    }
}

// Timeline:
// - **Real-time (weight > 5)**: User asked complex question → 
//   Instant iOS sends Congress results to Python for storage + backend insight extraction
//
// - **On App Close**: All queued interactions flush to backend in batch
//
// - **Periodic (if online)**: Every 5 minutes, sync any pending updates
//
// - **Offline Queue**: All requests persist to UserDefaults, process when online
```

### Benefits
✅ Complex interactions get Python insights immediately  
✅ Simple chatter doesn't overwhelm network  
✅ Works offline with queue resilience  
✅ On app close, batches reduce requests  

---

## 7. Coherence Score Thresholds & Failure Modes

### Current State
- BeliefSystem computes `coherenceScore: 0-100`
- No action taken if score drops

### What Should Happen

**Solution**: **Coherence monitoring with escalating responses**

```swift
enum CoherenceHealthState {
    case healthy(Double)       // > 70: All good
    case caution(Double)       // 50-70: Some tension
    case critical(Double)      // < 50: Major conflict
}

struct CoherenceHealthMonitor {
    func assessHealth(system: BeliefSystem) -> CoherenceHealthState {
        let score = system.coherenceScore
        
        if score > 70 { return .healthy(score) }
        else if score > 50 { return .caution(score) }
        else { return .critical(score) }
    }
    
    func respondToCoherenceState(_ state: CoherenceHealthState) {
        switch state {
        case .healthy(let score):
            // ✅ No action needed
            print("Belief system coherent at \(Int(score))%")
            
        case .caution(let score):
            // ⚠️ Flag beliefs with high tension
            flagUnresolvedTensions()
            
            // Suggest user reflection
            let suggestion = Insight(
                content: "Several beliefs are pulling in different directions (coherence \(Int(score))%). Would you like to explore the tension?",
                category: .systemAlert,
                source: "Coherence monitor"
            )
            dispatch(suggestion)
            
        case .critical(let score):
            // 🚨 Pause and require resolution
            pauseCongressDebates()
            
            let alert = Insight(
                content: "⚠️ CRITICAL: Core beliefs are in conflict (coherence \(Int(score))%). Your belief system needs reorganization.\n\nSuggested: Review the oscillating beliefs below and choose your actual position.",
                category: .systemAlert,
                source: "Critical coherence failure"
            )
            showInterruptiveAlert(alert)
            
            // Show consolidated review
            showBeliefConsolidationUI()
        }
    }
    
    private func flagUnresolvedTensions() {
        // In BeliefsNetworkView, show orange warnings on oscillating beliefs
        let oscillatingBeliefs = beliefSystem.nodes.filter { belief in
            belief.analyzeTension().unresolvedFlag
        }
        
        // Display them at top of Beliefs tab
        displayBeliefsNeedingAttention(oscillatingBeliefs)
    }
    
    private func pauseCongressDebates() {
        // In AppCoordinator, set flag
        self.congressDebatesPaused = true
        
        // Message to user
        chatManager.add(ChatMessage(
            role: .assistant,
            content: "I'm hitting a coherence wall - my beliefs are conflicting. Help me sort this out?"
        ))
    }
    
    private func showBeliefConsolidationUI() {
        // New view: BeliefConsolidationView
        // Shows:
        // 1. Oscillating/conflicting beliefs
        // 2. Their revision histories
        // 3. Prompts user: "Which position do you actually hold?"
        // 4. Locks belief to chosen weight
        
        coordinator.showBeliefConsolidation(beliefs: conflictedBeliefs)
    }
}

// Usage in AppCoordinator
override func processUserQuery(_ query: String, userMessage: ChatMessage? = nil) {
    // ... existing code ...
    
    // After update, check coherence
    let healthMonitor = CoherenceHealthMonitor()
    let state = healthMonitor.assessHealth(system: beliefSystem)
    healthMonitor.respondToCoherenceState(state)
    
    if case .critical = state {
        // Pause further queries
        self.congressDebatesPaused = true
        return
    }
}
```

### Threshold Responses

| Score | Response | Action |
|-------|----------|--------|
| **>70** | ✅ Healthy | Continue normally |
| **60-70** | ⚠️ Caution | Flag oscillating beliefs; suggest review |
| **50-59** | ⚠️ Warning | Prompt user to resolve tensions |
| **<50** | 🚨 Critical | **PAUSE Congress** + Show consolidation UI |

### Consolidation UI Flow

```
Coherence Critical Alert
↓
"Your beliefs are conflicting. Let's resolve them."
↓
List oscillating beliefs (each shows revision history)
↓
For each belief:
  "You've swung between weights 6 and 8."
  "You said: 'Logic suggests...' and 'Value suggests...'"
  "Which do you actually believe?"
  [Choose 6] [Choose 8] [Pick middle ground: 7]
↓
Lock selected weight + note reason
↓
Recalculate coherence
↓
If >60: Resume Congress debates
```

---

## Implementation Roadmap

### Phase 5.1: Intelligence Depth (Recommended Next)

1. **Belief Tension Analysis** (Task 1)
   - Add `analyzeTension()` to BeliefNode
   - Show warnings in BeliefsNetworkView
   - Estimate effort: **2-3 hours**

2. **Perspective Dominance** (Task 2)
   - Add `PerspectiveDominanceTracker` to SyncCoordinator
   - Auto-generate self-insights about reasoning tendencies
   - Estimate effort: **2 hours**

3. **Profound Insight Scoring** (Task 3)
   - Implement multi-criteria scoring function
   - Auto-mark ✨ insights
   - Estimate effort: **3 hours**

4. **Belief Emergence** (Task 4)
   - Add `BeliefEmergenceMonitor` 
   - Auto-create learned beliefs from patterns
   - Estimate effort: **3-4 hours**

5. **Pattern Aggregation** (Task 5)
   - Add `PatternAggregator` to MemoryViewTab
   - Show confirmed + pending patterns
   - Estimate effort: **2-3 hours**

6. **Sync Timing Strategy** (Task 6)
   - Implement `SmartSyncScheduler`
   - Real-time for complex, batch for simple
   - Estimate effort: **1-2 hours**

7. **Coherence Monitoring** (Task 7)
   - Add `CoherenceHealthMonitor`
   - Implement consolidation UI
   - Estimate effort: **3-4 hours**

**Total estimated effort**: 16-22 hours for full intelligence depth

---

## Files to Create/Modify

```
New Files:
- BeliefTensionAnalysis.swift (100 lines)
- PerspectiveDominanceTracker.swift (200 lines)
- InsightScoringEngine.swift (150 lines)
- BeliefEmergenceMonitor.swift (200 lines)
- PatternAggregator.swift (250 lines)
- SmartSyncScheduler.swift (100 lines)
- CoherenceHealthMonitor.swift (200 lines)
- BeliefConsolidationView.swift (300 lines)

Modified Files:
- BeliefNode.swift (add tensionAnalysis)
- AppCoordinator.swift (integrate all monitors)
- LogicDetailView.swift (show profound insights with badges)
- BeliefsNetworkView.swift (show tension warnings)
- MemoryViewTab.swift (show pattern aggregation)
- SettingsView.swift (show reasoning dominance)
```

---

## Philosophy

These mechanisms transform Sovern from a **transcript recorder** into a **self-aware reasoner**:

- **Tension detection** = Self-observing contradictions
- **Dominance tracking** = Self-observing personality
- **Insight scoring** = Self-evaluating reasoning quality
- **Belief emergence** = Self-extending conceptual framework
- **Pattern aggregation** = Self-learning about human
- **Coherence monitoring** = Self-maintaining integrity

This is the **recursive loop in action**: Congress debates → Memory introspection → Belief evolution → Next Congress uses evolved self-model.

