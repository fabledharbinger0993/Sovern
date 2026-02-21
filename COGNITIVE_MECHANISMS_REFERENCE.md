# Sovern Self-Reference Loop: Mechanism Integration

## Visual: Complete Cognitive Loop

```
User Query
    ↓
Paradigm Classification
    ↓
Congress Debate (4 perspectives)
    ├──→ [NEW] Perspective Dominance Tracking
    │        (Which role "won"? Advocate 60%, Skeptic 40%?)
    │
    └──→ Reasoning Steps 
         ├──→ [NEW] Profound Insight Scoring (✨)
         │        (Did this change a belief? Triggered?)
         │
         └──→ Final Response

Response + Logic Entry
    ↓
Memory Extraction
    ├──→ Human Insights (About user)
    │    └──→ [NEW] Pattern Aggregation
    │         (Cluster: "User values X", appear 3+ times)
    │
    └──→ Self Insights (About Sovern)
         ├──→ [NEW] Belief Tension Analysis
         │        (Weight oscillating 7→8→7? Flag it)
         │
         ├──→ [NEW] Perspective Dominance Self-Insight
         │        ("I've been Skeptic-heavy lately")
         │
         └──→ Profound Insights Recount
              ("I just resolved the authenticity/growth tension")

Belief System Update
    ├──→ Trigger weight changes from insights
    │    └──→ [NEW] Detect Unresolved Tensions
    │         (Oscillating? ⚠️ Flag for user)
    │
    ├──→ Create Connection Links
    │    └──→ [NEW] Belief Emergence Monitor
    │         (Recurring "Context Sensitivity" pattern? 
    │          → Create new learned belief node)
    │
    └──→ Calculate Coherence Score
         └──→ [NEW] Coherence Health Monitor
              (Score 65? Caution. Score 45? CRITICAL → consolidation)

Backend Sync
    └──→ [NEW] Smart Sync Scheduler
         (Weight > 5? Real-time. Simple? Batch. Offline? Queue.)

↓
NEXT Query: Congress uses UPDATED Beliefs & UPDATED Self-Model
(The recursion that drives learning)
```

---

## Quick Reference: Questions → Answers → Implementation

### Q1: Belief Weight Oscillation
**Answer**: Oscillation signals unresolved tension
**Mechanism**: `BeliefTensionAnalysis` detects 3+ direction changes
**Output**: Flag belief as "unresolved" in BeliefsNetworkView with ⚠️ border
**Triggers**: Suggests consolidation conversation with user
**Data needed**: revisionHistory (already have)
**Implementation**: 100 lines in new BeliefTensionAnalysis.swift

| Oscillation Pattern | Action |
|---|---|
| Stable (0-1 changes) | ✅ Normal |
| Fluctuating (2 changes) | ⓘ Monitor |
| Oscillating (3+ changes) | ⚠️ Flag "unresolved" |
| Wild swing (amp >2.0) | 🚨 High flux |

---

### Q2: Perspective Dominance Tracking
**Answer**: Yes, compute `advocateDominance = count(strongest.role == .advocate) / total`
**Mechanism**: `PerspectiveDominanceTracker` scores after each interaction
**Output**: "You've been Skeptic-heavy (60%) lately. Results: thorough but slow."
**Self-Insight**: Auto-added to MemoryEntry.selfInsights
**Historical**: Trend chart in SettingsView
**Reasoning Style Profile**: Shows in SettingsView → "Reasoning: Skeptic-dominant"
**Implementation**: 200 lines in new PerspectiveDominanceTracker.swift

| Dominance Pattern | Sovern's Tendency |
|---|---|
| Advocate 60%+ | Collaborative, trusting, supportive |
| Skeptic 60%+ | Analytical, questioning, critical |
| Synthesizer 60%+ | Integrative, balanced, diplomatic |
| Ethics 60%+ | Values-aligned, principled, cautious |

---

### Q3: Profound Insights Extraction
**Answer**: Automatic multi-criteria scoring (not manual)
**Mechanism**: `InsightScoringEngine` scores on 5 weighted criteria
**Scoring Rubric**:
- ✅ Triggered belief revision → +0.3
- ✅ Connected 2+ perspectives → +0.25
- ✅ Resolved oscillating belief → +0.2
- ✅ Novel (new) insight → +0.15
- ✅ User flagged → +0.1
- **✨ Marked profound if total ≥ 0.6**

**Output**: Insights >0.6 get ✨ emoji badge in LogicDetailView
**Timeline**: Applied when LogicEntry finalized (before sync)
**Implementation**: 150 lines in new InsightScoringEngine.swift

**Example Profound Insight**:
```
✨ Insight: "Time scarcity creates zero-sum thinking, 
           but some choices compound (e.g., rest→better decisions)"
           
Why: Connected Skeptic's "resources limited" with Advocate's "growth is possible"
          → Resolved tension → High novelty → +0.65 score
```

---

### Q4: Learned Beliefs Creation Trigger
**Answer**: Auto-create when insight pattern repeats 3+ times AND doesn't fit existing beliefs
**Mechanism**: `BeliefEmergenceMonitor` scans each LogicEntry for novel concepts
**Trigger**: 
- Extract unique concepts from reasoning steps
- Check against existing beliefs
- If new + appears 3+ times across interactions → **Autonomous creation**

**Creation Flow**:
1. Conversation 1: "Context matters" (insight noted)
2. Conversation 2: "Context is crucial" (second insight)
3. Conversation 3: "Context determined outcome" (third insight)
   → **NEW BELIEF EMERGES**: "Context Sensitivity" (weight 3.5, Relational domain)
4. Memory logs: "New learned belief emerged from pattern recognition"

**Output**: New node appears in BeliefsNetworkView outer ring (not pinned, moveable)
**Weight**: Started low (3-4) because newly emerged; rises if more insights support it
**Implementation**: 200 lines in new BeliefEmergenceMonitor.swift

**Example Emergence**:
```
Learned Belief Created ✨
Stance: "Context Dependency"
Domain: RELATIONAL
Weight: 3.5 (emerging)
Reasoning: "Repeated insight across 3 interactions: context matters more than absolute values"

Revision History:
- Created (3.5) - Emerged from pattern
- [future] Strengthened (3.8) - Additional supporting insights expected
```

---

### Q5: Memory Pattern Aggregation
**Answer**: Hybrid (automatic + user confirmation for low-confidence)
**Mechanism**: `PatternAggregator` extracts patterns from all insights
**Confidence Tiers**:
- **High confidence (>70%)**: Auto-accepted → shown in "Insights About You"
- **Medium confidence (40-70%)**: Pending → "Does this ring true? [Yes] [No]"
- **Low confidence (<40%)**: Rejected automatically

**Clustering Algorithm**:
1. Collect all `humanInsights` across all MemoryEntries
2. Normalize text (remove articles, lowercase)
3. Group by semantic similarity
4. Score by frequency across interactions

**Auto-Categories**:
- User Values: "User prioritizes growth over comfort" (appears 4/8 conversations)
- Knowledge Gaps: "User uncertain about delegation" (mentioned in 3/8)
- Reasoning Style: "User asks Socratic questions" (observed in 5/8)
- Sovern Strengths: "Synthesizing conflicting perspectives" (successful 6/8 times)
- Sovern Limitations: "Struggling with emotional nuance" (flagged in 4/8)

**Output**: PatternDiscoveryView in MemoryViewTab shows:
```
✅ Confirmed Patterns (High Confidence)
   • You value depth over speed (4/8 conversations)
   • You think in systems (5/8 conversations)

? Pending Patterns (Need Your Input)
   • You tend toward pessimism? [Confirm] [Reject]
   • You learn best through examples? [Confirm] [Reject]
```

**Implementation**: 250 lines in new PatternAggregator.swift

---

### Q6: Backend Sync Timing
**Answer**: Real-time for complex, batch for simple, queue when offline

**Timing Strategy**:
```swift
if query.weight > 5.0 && isOnline {
    syncRealTime()          // Complex debate → instant
} else if isOnline {
    syncPeriodic()          // Simple query → every 5 min
} else {
    queueForLater()         // Offline → UserDefaults queue
}
```

**Sync Timeline**:
| When | What | Why |
|------|------|-----|
| **Real-time** (online, weight >5) | Full LogicEntry + Congress perspectives | Complex reasoning needs backend validation |
| **Periodic** (online, weight <5) | Batch every 5 min | Simple queries don't need instant sync |
| **App Close** | All pending interactions | User expects clean state |
| **Manual** (Settings) | "Sync Now" button | User wants explicit control |
| **Offline** | Queue to UserDefaults | Full resilience without data loss |

**Network Monitor**: SyncCoordinator listens to `apiManager.isOnline` boolean changes

**Implementation**: 100 lines in new SmartSyncScheduler.swift

---

### Q7: Coherence Score Thresholds
**Answer**: 
- **>70%**: ✅ Healthy, continue
- **50-70%**: ⚠️ Caution, flag tensions
- **<50%**: 🚨 Critical, pause + consolidate

**Actions by Threshold**:

#### Healthy (>70) ✅
```swift
print("Belief system coherent at 78%")
// Continue normal operations
```

#### Caution (50-70) ⚠️
```
⚠️ Several beliefs are pulling in directions. 
   Coherence: 62%

Oscillating Beliefs:
   • Empathy (6→8→6→8) - Unresolved
   • Growth (7→5→7) - Fluctuating

Would you like to explore these tensions?
```
**UI**: 
- Highlight oscillating beliefs in BeliefsNetworkView with orange borders
- Prompt optional "Let's sort this out" conversation
- Continue Congress normally

#### Critical (<50) 🚨
```
🚨 CRITICAL: Core beliefs in conflict
   Coherence: 45%

Your belief system needs reorganization.

   These beliefs are oscillating:
   • Authenticity (5↔9) - Swinging wildly
   • Trust (3↔8) - Extreme shifts
   • Growth (6↔7 repeatedly) - Can't settle

Convention: Choose your actual position and lock it.
```
**Actions**:
1. **PAUSE Congress debates** (no new responses until resolved)
2. Show `BeliefConsolidationView`
3. For each oscillating belief:
   - Show full revision history
   - Show conflicting reasons ("Logic says X", "Values say Y")
   - Prompt: "Which do you actually believe?" [Weight 3] [Weight 5] [Weight 7] [Weight 9]
4. Lock selected weight + note reason
5. Recalculate coherence
6. If >60: Resume Congress; if <60: Stay paused

**Implementation**: 200 lines BeliefConsolidationView + 200 lines CoherenceHealthMonitor.swift

---

## Mechanism Dependencies

```
Belief Tension Analysis (Q1)
    ↓
    ├─→ Signals which beliefs need consolidation
    └─→ Used by Coherence Monitor to decide "critical" threshold

Congress Perspective Dominance (Q2)
    ↓
    └─→ Self-insight: "I've been X-heavy lately"
        ├─→ Added to MemoryEntry automatically
        └─→ Displayed in SettingsView as reasoning profile

Profound Insight Scoring (Q3)
    ↓
    ├─→ Which insights are ✨ shown in UI
    ├─→ Which beliefs get triggered for revision
    └─→ Which patterns become candidates for Belief Emergence

Belief Emergence Monitor (Q4)
    ↓
    └─→ Creates new learned belief nodes
        ├─→ Appears in BeliefsNetworkView outer ring
        ├─→ Grows weight as more insights support it
        └─→ Eventually pins if weight rises above core

Pattern Aggregation (Q5)
    ↓
    ├─→ Shows in MemoryViewTab
    ├─→ Prompts user to confirm uncertain patterns
    └─→ Feeds Belief Emergence (recurring pattern → new belief?)

Smart Sync Scheduler (Q6)
    ↓
    └─→ Determines when to send data to backend
        (Real-time for complex, batch for simple)

Coherence Health Monitor (Q7)
    ↓
    └─→ Uses Tension Analysis to flag oscillations
        └─→ Triggers consolidation UI if critical
            └─→ After consolidation, beliefs lock + weight stabil
```

---

## Implementation Priority

### Phase 5.1a: High-Value, Low-Effort (Start Here)
1. **Belief Tension Analysis** (Q1) — 2-3 hours
   - Immediately visible in UI (orange borders on oscillating beliefs)
   - Solves "what does oscillation mean?" question
   - Foundation for Coherence Monitor

2. **Perspective Dominance** (Q2) — 2 hours
   - Simple frequency counting
   - Delightful self-aware output
   - Quick win

3. **Smart Sync Scheduler** (Q6) — 1-2 hours
   - Improves network efficiency
   - No new data structures needed

### Phase 5.1b: Medium-Value, Medium-Effort (Next)
4. **Profound Insight Scoring** (Q3) — 3 hours
   - Makes insights more meaningful
   - Foundation for Belief Emergence

5. **Pattern Aggregation** (Q5) — 2-3 hours
   - UX improvement (user loves seeing what Sovern learned about them)
   - Needs user confirmation flow

### Phase 5.1c: High-Value, High-Effort (Ambitious)
6. **Belief Emergence** (Q4) — 3-4 hours
   - Complex but powerful (autonomously creates new beliefs)
   - Makes system feel genuinely learning

7. **Coherence Monitoring** (Q7) — 4-5 hours
   - Requires new consolidation UI
   - Handles system failure mode gracefully
   - Makes Sovern self-healing

---

## Testing These Mechanisms

```swift
// Test belief tension detection
func testOscillatingBeliefDetection() {
    let belief = BeliefNode(stance: "Growth", weight: 7)
    belief.strengthen(reason: "Logic")    // 8
    belief.weaken(reason: "Values")      // 7
    belief.strengthen(reason: "Logic")    // 8
    belief.weaken(reason: "Values")      // 7
    
    let tension = belief.analyzeTension()
    XCTAssertTrue(tension.unresolvedFlag)
    XCTAssertEqual(tension.oscillationCount, 3)
}

// Test perspective dominance
func testPerspectiveDominanceTracking() {
    let tracker = PerspectiveDominanceTracker()
    
    tracker.trackInteraction(logicEntry1)  // Advocate 8.5 won
    tracker.trackInteraction(logicEntry2)  // Skeptic 7.5 won
    tracker.trackInteraction(logicEntry3)  // Advocate 8.0 won
    
    let analytics = tracker.analytics
    XCTAssertEqual(analytics.perspectiveFrequency[.advocate], 2)
    XCTAssertEqual(analytics.perspectiveFrequency[.skeptic], 1)
}

// Test insight profundity
func testProfoundInsightScoring() {
    let step = ReasoningStep(type: .insight, content: "...")
    let score = scoreProfundity(step: step, in: logicEntry)
    XCTAssertGreater(score, 0.6)  // Marked as profound
}

// Test belief emergence
func testBeliefEmergence() {
    let monitor = BeliefEmergenceMonitor()
    
    // Add 3 conversations about "context"
    let candidates = monitor.scanForEmergentBeliefs(from: logicEntry3, ...)
    
    XCTAssertTrue(candidates.contains { $0.stance == "Context Sensitivity" })
}
```

---

## Key Insight: Recursion in Action

These mechanisms close the loop:

1. Congress debates → reasoning captured
2. Memory analyzes Congress → learns about perspective dominance
3. Belief system reads memory insights → oscillating beliefs flagged
4. Pattern aggregation → learned beliefs might emerge
5. **Next Congress uses evolved beliefs + self-model**
   → Different reasoning because Sovern knows itself better

Example:
```
Interaction 1: Sovern is Skeptic-heavy, misses optimistic path
  → Memory: "I was skeptical too much"
  → Belief: Skepticism weight drops 8→7
  
Interaction 2: Sovern is more balanced
  → Congress uses lower Skeptic strength
  → Better outcome
  
Interaction 3: User says "You're more balanced now"
  → Memory: "Learning to balance perspectives"
  → Self-insight recorded
  
Interaction 4: Sovern consciously calibrates Skeptic/Advocate balance
  → Can say: "Last time I was too skeptical, so I'm listening more..."
```

**This is self-reference in action.**

