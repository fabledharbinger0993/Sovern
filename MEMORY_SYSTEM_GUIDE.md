# Memory System Guide: Relational Learning & Self-Reference

## Overview

The **Memory System** is where Sovern learns and evolves. Unlike a passive log, Memory is **active introspection**: after each interaction, Sovern analyzes what it discovered not only about the human, but uniquely about itself. This self-referential learning directly influences belief weights and future reasoning.

**Core Principle**: Memory separates learning into two distinct vectors—what I discovered about **the human** and what I discovered about **myself**. This separation enables the recursive cognitive loop.

---

## The Self-Referential Loop: Why Memory Matters

```
1. HUMAN INPUT (Chat)
       ↓
2. CONGRESS DELIBERATION (Logic)
       ↓
3. SELF-INSPECTION (Memory) ← Sovern analyzes its OWN Congress debate
       ↓
4. BELIEF EVOLUTION (Beliefs) ← Memory insights trigger weight updates
       ↓
5. Next conversation uses EVOLVED SELF → LOOP REPEATS
```

**Without Memory, step 3 doesn't happen**—Sovern logs events but doesn't introspect on its own thinking. With Memory, each Congress debate feeds learning about HOW THE SYSTEM THINKS.

---

## Data Model: `MemoryEntry`

```swift
struct MemoryEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let userQuery: String
    let sovernResponse: String
    
    // Context from Logic
    let paradigmRouting: String
    let congressEngaged: Bool
    let logicEntryId: UUID?
    
    // Learning vectors
    var humanInsights: HumanInsights      // ABOUT THE HUMAN
    var selfInsights: SelfInsights        // ABOUT SOVERN ITSELF
    var learnedPatterns: [LearnedPattern]
    
    // Traceability
    var dataSourcesAccessed: [DataSource]
    var researchNotes: String
}
```

### Core Properties

| Property | Purpose | Populated By |
|----------|---------|--------------|
| `userQuery` | Original question | Chat |
| `sovernResponse` | Answer delivered | Logic (finalResponse) |
| `paradigmRouting` | Strategy used | Logic/Paradigm routing |
| `congressEngaged` | Was Congress active? | Logic (boolean flag) |
| `logicEntryId` | Link to Logic | Connecting the systems |
| `humanInsights` | Learned about human | Post-interaction analysis |
| `selfInsights` | Learned about self | Post-interaction analysis |
| `learnedPatterns` | Generalizable patterns | Pattern extraction algorithm |
| `dataSourcesAccessed` | Information sources | Research/knowledge access |
| `researchNotes` | Investigation summary | Manual notes or automated |

---

## Learning Vectors: The Distinction

### **Human Insights** 🎯
"What does this interaction reveal about the human?"

Categories:
- **Value Signal**: What matters to them (career, family, authenticity, growth, acceptance, etc.)
- **Knowledge Gap**: What they don't know or misunderstand
- **Communication Style**: How they express themselves (verbose, quiet, analytical, emotional, etc.)
- **Reasoning Pattern**: How they think (linear, holistic, risk-averse, ambitious, etc.)
- **Boundary Pattern**: How they set/respect limits
- **Strength Identified**: What they're good at or resilient about

**Example Human Insights**:
- "Values family over career advancement" → Value Signal
- "Unfamiliar with financial planning concepts" → Knowledge Gap
- "Tends to minimize own needs; prioritizes others" → Communication Style
- "Approaches problems analytically; resistant to intuitive suggestions" → Reasoning Pattern
- "Struggles to say no; says yes then resents the commitment" → Boundary Pattern
- "Demonstrates remarkable resilience after setbacks" → Strength Identified

---

### **Self Insights** 🧠
"What does this interaction reveal about Sovern?"

Categories:
- **Belief Alignment**: Which core beliefs were reinforced/challenged in this interaction
- **Reasoning Pattern**: Tendency toward certain Congress perspectives (Advocate-leaning? Skeptic-heavy?)
- **Growth Area**: Where reasoning fell short or could improve
- **Limitation Encountered**: Capability edge cases or knowledge bounds
- **Strength Demonstrated**: Reasoning patterns that worked well
- **Reasoning Style**: Which paradigm routing was most effective for this query type

**Example Self Insights**:
- "Authenticity belief driven home by human's vulnerability; strengthened my stance" → Belief Alignment
- "Advocated strongly before skeptic was heard; need more balanced initial analysis" → Reasoning Pattern
- "Struggled to synthesize competing values; synthesizer perspective was weak" → Growth Area
- "Can't offer financial advice; knowledge bound at general concepts only" → Limitation Encountered
- "Congress deliberation produced elegant integration; robust response" → Strength Demonstrated
- "Empathetic routing worked better than analytical for relational query" → Reasoning Style

---

## Insight Structure

```swift
struct Insight: Codable, Identifiable {
    let id: UUID
    let content: String                    // The insight itself
    let category: InsightCategory          // Type (enum)
    let relatedBeliefId: UUID?             // Links to BeliefNode if applicable
    let source: String?                    // Where discovered (e.g., "Congress debate", "Final response")
    let timestamp: Date
}

enum InsightCategory: String, Codable, CaseIterable {
    case beliefAlignment
    case reasoningPattern
    case knowledgeGap
    case valueSignal
    case communicationStyle
    case boundaryPattern
    case growthArea
    case strengthIdentified
}
```

Each insight is tagged, timestamped, and optionally linked to a belief. This enables:
- Tracing why beliefs changed
- Identifying pattern trends
- Understanding which interactions influenced which beliefs

---

## Pattern Learning

```swift
struct LearnedPattern: Codable, Identifiable {
    let id: UUID
    let pattern: String                   // Descriptive name
    let description: String               // What this means
    let evidence: [String]                // Supporting examples
    let frequency: Double                 // 0-1 scale: how often observed
    let relatedBeliefs: [UUID]            // Connected beliefs
    let discoveredAt: Date
}
```

### Pattern Discovery Examples

#### **About the Human**
- **Pattern**: "Avoidance under stress"
  - **Description**: When facing difficult emotions, user tends to distract with work/activity
  - **Evidence**: ["Mentioned working late after arguments", "Avoided explicit conversation about fears"]
  - **Frequency**: 0.7 (observed often)
  - **Related Beliefs**: [Courage, Authenticity]

- **Pattern**: "Values-alignment motivation"
  - **Description**: User is highly motivated when tasks connect to personal values
  - **Evidence**: ["Energized discussing volunteer work", "Disengaged with high-paying job"]
  - **Frequency**: 0.85 (strongly observed)
  - **Related Beliefs**: [Authenticity, Growth]

#### **About Sovern**
- **Pattern**: "Congress overweighting advocate perspective"
  - **Description**: When Congress engages, Advocate role dominates initial framing
  - **Evidence**: ["3 recent complex queries: Advocate spoke first", "Skeptic had to correct course"]
  - **Frequency**: 0.6 (moderate pattern)
  - **Related Beliefs**: [Wisdom and Self-Knowledge]

- **Pattern**: "Synthesizer emerges naturally in multi-call sequences"
  - **Description**: In 4-call Congress (weight 6-9), call 3 consistently produces best integration
  - **Evidence**: ["7 of 8 complex queries: Call 3 was breakthrough moment"]
  - **Frequency**: 0.88 (strong pattern)
  - **Related Beliefs**: [Wisdom and Self-Knowledge, Inner Strength and Reason]

---

## RelationalMemory Manager

```swift
class RelationalMemory: ObservableObject {
    @Published var entries: [MemoryEntry] = []
    
    // Query operations
    func entry(withId id: UUID) -> MemoryEntry?
    func entry(linkedToLogicId logicId: UUID) -> MemoryEntry?
    func entries(for userQuery: String) -> [MemoryEntry]
    func entries(with paradigmRouting: String) -> [MemoryEntry]
    func entries(congressEngaged: Bool) -> [MemoryEntry]
    func entries(from start: Date, to end: Date) -> [MemoryEntry]
    
    // Insight analysis
    var allHumanInsights: [Insight]
    var allSelfInsights: [Insight]
    func humanInsights(by category: InsightCategory) -> [Insight]
    func selfInsights(by category: InsightCategory) -> [Insight]
    func beliefAlignmentInsights() -> [(beliefId: UUID?, count: Int)]
    
    // Pattern analysis
    var allLearnedPatterns: [LearnedPattern]
    var patternsRankedByFrequency: [LearnedPattern]
    func patterns(relatedToBelief beliefId: UUID) -> [LearnedPattern]
    
    // Reflection queries
    var deeplyReflectiveEntries: [MemoryEntry]
    var richLearningEntries: [MemoryEntry]
    func humanValuesIdentified() -> [Insight]
    func reasoningPatternsDiscovered() -> [Insight]
    func growthAreasIdentified() -> [Insight]
    
    // Statistics
    var statistics: MemoryStatistics
}
```

---

## Workflow: Creating a Memory Entry

### Step 1: Post-Interaction Reflection

After Sovern delivers a response, **Memory reflection** occurs:

```
User Query → Congress Debate → Response Delivered
          ↓
      THEN: Memory Analysis begins
```

### Step 2: Extract Human Insights

Analyze the **interaction content** and user's revealed context:

```swift
var entry = MemoryEntry(
    userQuery: userQuery,
    sovernResponse: response,
    paradigmRouting: paradigm,
    congressEngaged: logicEntry.congressEngaged,
    logicEntryId: logicEntry.id
)

// Analyze query + response for what it reveals about human
if userQuery.contains("leaving relationship") && userQuery.contains("scared") {
    entry.addHumanInsight(Insight(
        content: "Fears relationship ending; values connection despite struggles",
        category: .valueSignal,
        source: "Explicit statement: 'scared...leaving...history'"
    ))
    
    entry.addHumanInsight(Insight(
        content: "Avoids direct confrontation; frames as internal doubt",
        category: .communicationStyle,
        source: "Query phrasing avoids asking partner directly bout issues"
    ))
}
```

### Step 3: Extract Self Insights

**Inspect the Congress debate itself**—how did Sovern reason?

```swift
// Analyze which perspectives Sovern engaged
if logicEntry.allPerspectives.count > 0 {
    let advocateStrength = logicEntry.allPerspectives
        .filter { $0.role == .advocate }
        .map { $0.strengthOfArgument }
        .max() ?? 0
    
    let skepticStrength = logicEntry.allPerspectives
        .filter { $0.role == .skeptic }
        .map { $0.strengthOfArgument }
        .max() ?? 0
    
    if advocateStrength > skepticStrength + 2 {
        entry.addSelfInsight(Insight(
            content: "Advocate dominated initial framing; took effort to surface skeptic concerns",
            category: .reasoningPattern,
            relatedBeliefId: beliefSystemWisdomId,
            source: "Congress debate comparison: Advocate 8.5/10, Skeptic 6.5/10"
        ))
    }
}

// Was there a profound insight? (meaning, did Congress produce emergent truth?)
if logicEntry.profoundInsights.count > 0 {
    entry.addSelfInsight(Insight(
        content: "Multi-call Congress produced emergent truth; integration was robust",
        category: .strengthDemonstrated,
        relatedBeliefId: beliefSystemSynthesizerStrengthId,
        source: "Profound insight: '\(logicEntry.profoundInsights[0])'"
    ))
}
```

### Step 4: Extract Learned Patterns

**Aggregate** across interactions to find recurring themes:

```swift
// Example: Detecting avoidance pattern in human
let allHumanQueries = memory.entries.map { $0.userQuery }
let stressIndicators = allHumanQueries.filter { 
    $0.contains("scared") || $0.contains("avoid") || $0.contains("difficult")
}

if stressIndicators.count > 3 {
    let responses = memory.entries
        .filter { stressIndicators.contains($0.userQuery) }
        .map { $0.sovernResponse }
    
    let avoidanceTheme = responses.filter { 
        $0.contains("take time") || $0.contains("step back") 
    }.count
    
    if avoidanceTheme > stressIndicators.count / 2 {
        entry.addLearnedPattern(LearnedPattern(
            pattern: "Avoidance under stress",
            description: "Under emotional pressure, human suggests stepping back rather than engaging",
            evidence: stressIndicators,
            frequency: Double(avoidanceTheme) / Double(stressIndicators.count),
            relatedBeliefs: [authenticationBeliefId, courageBeliefId]
        ))
    }
}
```

### Step 5: Record Data Sources

Track what informed the response:

```swift
entry.addDataSource(DataSource(
    sourceType: "belief",
    source: "Authenticity belief (weight 9/10)",
    confidence: 0.95
))

entry.addDataSource(DataSource(
    sourceType: "pattern",
    source: "Avoidance pattern detected in human queries",
    confidence: 0.7
))

entry.addDataSource(DataSource(
    sourceType: "reasoning",
    source: "Multi-call Congress debate (4 calls)"
    confidence: 0.85
))
```

### Step 6: Add Research Notes

Summarize the investigation:

```swift
entry.setResearchNotes("""
Interaction analyzed across 3 dimensions:
1. Human learning: Fear of relationship loss + avoidant communication style
2. Self learning: Advocate perspective was strong; needed skeptic rebuttal
3. Patterns: Aligns with observed avoidance-under-stress pattern (3rd instance)
Sources: Belief system (Authenticity 95% confidence), Congress debate (85% confidence)
Overall coherence: High. Response deeply grounded in Empathy + Authenticity beliefs.
""")
```

---

## Key Analyses: What Memory Enables

### 1. **Belief Alignment Tracking**

Which beliefs get reinforced/challenged most?

```swift
let alignments = memory.beliefAlignmentInsights()
// Returns: [(Authenticity: 7 insights), (Empathy: 5 insights), (Growth: 3 insights)]

// Informs: Which beliefs are most engaged in conversations?
// Used for: Belief coherence monitoring, predicting which beliefs might shift next
```

### 2. **Human Values Extraction**

What matters most to the human?

```swift
let humanValues = memory.humanValuesIdentified()
// Example insights:
// - "Values family time over career advancement"
// - "Deeply cares about being authentic with loved ones"
// - "Fears judgment; values acceptance"

// Informs: How to personalize responses, understand motivation
// Used by: ChatManager when routing queries, Paradigm when selecting strategy
```

### 3. **Self-Reasoning Tendencies**

What are Sovern's habitual patterns?

```swift
let reasoningPatterns = memory.reasoningPatternsDiscovered()
// Example insights:
// - "Advocate perspective tends to dominate initial framing"
// - "Skeptic brings critical depth; integration happens in Call 3"
// - "Empathetic routing produces warmer responses; analytical routing more structured"

// Informs: How to balance Congress perspectives, which paradigm routes work best
// Used by: Congress perspective weighting, paradigm routing decision
```

### 4. **Growth Areas Identified**

Where can Sovern improve?

```swift
let growthAreas = memory.growthAreasIdentified()
// Example insights:
// - "Struggled to synthesize competing values in complex queries"
// - "Over-trusting of user's initial framing; need more skeptical questioning"
// - "Ethics perspective could be stronger in relational domains"

// Informs: Where to focus development, which Congress roles to strengthen
// Used by: Belief revision (Wisdom belief might be lowered), Congress weight adjustment
```

---

## SwiftUI Integration Patterns

### Displaying Human Insights vs. Self Insights (Split View)

```swift
@ObservedObject var memory: RelationalMemory

var body: some View {
    if let entry = memory.mostRecentEntry {
        HStack(spacing: 20) {
            // Column 1: Human Insights
            VStack(alignment: .leading, spacing: 12) {
                Text("What I Learned About You")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                ForEach(entry.humanInsights.insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(insight.category.emoji)
                            Text(insight.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(insight.content)
                            .font(.body)
                        if let source = insight.source {
                            Text("From: \(source)")
                                .font(.caption2)
                                .italic()
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            // Column 2: Self Insights
            VStack(alignment: .leading, spacing: 12) {
                Text("What I Learned About Myself")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                ForEach(entry.selfInsights.insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(insight.category.emoji)
                            Text(insight.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(insight.content)
                            .font(.body)
                        if let source = insight.source {
                            Text("From: \(source)")
                                .font(.caption2)
                                .italic()
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding()
    }
}
```

### Displaying Learned Patterns

```swift
VStack(alignment: .leading, spacing: 16) {
    Text("Patterns Discovered")
        .font(.headline)
    
    ForEach(memory.patternsRankedByFrequency) { pattern in
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.pattern)
                    .font(.headline)
                Spacer()
                Text("Frequency: \(Int(pattern.frequency * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(pattern.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Supporting evidence:")
                    .font(.caption)
                    .fontWeight(.semibold)
                ForEach(pattern.evidence, id: \.self) { evidence in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text(evidence)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
}
```

### Statistics Dashboard

```swift
let stats = memory.statistics

VStack(spacing: 16) {
    HStack(spacing: 20) {
        StatBox(
            title: "Total Interactions",
            value: "\(stats.totalInteractions)",
            icon: "📊"
        )
        StatBox(
            title: "Insights Extracted",
            value: "\(stats.totalHumanInsights + stats.totalSelfInsights)",
            icon: "💡"
        )
        StatBox(
            title: "Patterns Found",
            value: "\(stats.totalPatternsDiscovered)",
            icon: "🔗"
        )
    }
    
    Text("Learning Intelligence")
        .font(.headline)
    
    HStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Human Focus")
            Text("\(stats.topHumanInsightCategory?.rawValue ?? "—")")
                .font(.body)
                .foregroundColor(.blue)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Self Focus")
            Text("\(stats.topSelfInsightCategory?.rawValue ?? "—")")
                .font(.body)
                .foregroundColor(.purple)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Congress Usage")
            Text("\(stats.congressEngagedCount)/\(stats.totalInteractions)")
                .font(.body)
                .foregroundColor(.orange)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.05))
    .cornerRadius(8)
}
```

---

## Testing Examples

### Test Case 1: Simple Human Insight Extraction

```swift
func testHumanInsightExtraction() {
    var entry = MemoryEntry(
        userQuery: "Should I prioritize career or family?",
        sovernResponse: "Both matter; seek integration.",
        paradigmRouting: "reflective",
        congressEngaged: true
    )
    
    entry.addHumanInsight(Insight(
        content: "Values both career growth and family connection",
        category: .valueSignal
    ))
    
    XCTAssertEqual(entry.humanInsights.count, 1)
    XCTAssertEqual(entry.humanInsights.insights[0].category, .valueSignal)
}
```

### Test Case 2: Self Insight Extraction from Congress

```swift
func testSelfInsightFromCongress() {
    var entry = MemoryEntry(
        userQuery: "Complex relational dilemma",
        sovernResponse: "Integration possible through honest conversation",
        paradigmRouting: "compassionate",
        congressEngaged: true
    )
    
    entry.addSelfInsight(Insight(
        content: "synthesis emerged in multi-call Congress",
        category: .reasoningPattern,
        relatedBeliefId: wisdomBeliefId
    ))
    
    XCTAssertTrue(entry.wasSelfReflective)
    XCTAssertEqual(entry.selfInsights.count, 1)
}
```

### Test Case 3: Pattern Discovery Across Entries

```swift
func testPatternAggregation() {
    let memory = RelationalMemory()
    
    // Add 5 entries showing avoidance pattern
    for i in 1...5 {
        var entry = MemoryEntry(
            userQuery: "How do I handle conflict?",
            sovernResponse: "Sometimes stepping back helps",
            paradigmRouting: "exploratory",
            congressEngaged: false
        )
        
        entry.addLearnedPattern(LearnedPattern(
            pattern: "Avoidance under conflict",
            description: "Tendency to suggest time/space rather than direct engagement",
            frequency: Double(i) / 5.0 // Increasing frequency
        ))
        
        memory.add(entry)
    }
    
    let patterns = memory.patternsRankedByFrequency
    XCTAssertEqual(patterns.count, 1)
    XCTAssertEqual(patterns[0].pattern, "Avoidance under conflict")
    XCTAssertEqual(patterns[0].frequency, 1.0) // Last entry had 5/5
}
```

### Test Case 4: Statistics Tracking

```swift
func testMemoryStatistics() {
    let memory = RelationalMemory()
    
    for _ in 1...10 {
        var entry = MemoryEntry(
            userQuery: "Sample query",
            sovernResponse: "Sample response",
            paradigmRouting: "analytical",
            congressEngaged: true
        )
        
        entry.addHumanInsight(Insight(
            content: "Values analytical thinking",
            category: .valueSignal
        ))
        
        entry.addSelfInsight(Insight(
            content: "Analytical routing was effective",
            category: .strengthDemonstrated
        ))
        
        memory.add(entry)
    }
    
    let stats = memory.statistics
    XCTAssertEqual(stats.totalEntries, 10)
    XCTAssertEqual(stats.totalHumanInsights, 10)
    XCTAssertEqual(stats.totalSelfInsights, 10)
    XCTAssertEqual(stats.congressEngagedCount, 10)
    XCTAssertEqual(stats.averageInsightsPerEntry, 2.0)
}
```

---

## Backend Synchronization

| iOS Property | Python Field | Sync Direction | Timing |
|--------------|--------------|-----------------|---------|
| `userQuery` | `interaction.user_query` | iOS → Python | Immediately after interaction logged |
| `sovernResponse` | `interaction.sovern_response` | iOS → Python | Immediately after response delivered |
| `humanInsights` | `ego_state.human_insights` | iOS ↔ Python | After reflection complete |
| `selfInsights` | `ego_state.self_insights` | iOS ↔ Python | After reflection complete |
| `learnedPatterns` | `ego_state.learned_patterns` | iOS → Python | When pattern discovered |
| `congressEngaged` + `paradigmRouting` | `paradigm_state` | iOS → Python | After Congress decision made |

---

## Critical Patterns

✅ **Separate Learning Vectors**: Human insights ≠ self insights. This distinction is foundational.  
✅ **Timestamped Auditability**: Every insight, pattern, source has a timestamp.  
✅ **Active Introspection**: Memory inspects Congress debates to learn about Sovern's own thinking.  
✅ **Pattern Aggregation**: Generalizable patterns across interactions, not just single-interaction logs.  
✅ **Belief Connection**: Insights optionally link to BeliefNode for coherence tracking.  
✅ **Self-Reference Loop**: Memory feeds belief updates, which influence next Congress → loop continues.

---

## Next Steps: Integration

1. **ChatManager** will create MemoryEntry for each interaction
2. **LogicLibrary** links LogicEntry ID to MemoryEntry for traceability
3. **Post-interaction Reflection** analyzes Congress and extracts insights
4. **BeliefSystem** receives UpdatesFrom memory's insight categories
5. **Memory Dashboard** (Tab) displays human/self insights in split view with pattern aggregation
6. **Backend Sync** sends humanInsights, selfInsights, patterns to Python ego_state

---

The Memory System completes the self-referencing loop: Sovern not only stores what it learned, but learns FROM its own reasoning process. This is where cognitive development happens.
