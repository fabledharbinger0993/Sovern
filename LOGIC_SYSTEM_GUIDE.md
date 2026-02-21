# Logic System Guide: Congress Debate & Reasoning

## Overview

The **Logic System** is the mainframe of Sovern's real-time reasoning. It captures every Congress debate with timestamped reasoning steps, perspective deliberation, iterative response drafting, and profound insights. The logic tab visualizes the complete thought process—how Sovern thinks, not just what it answers.

**Key Principle**: Logic is not hidden. Every debate, rejection, and insight is auditable and visible to the user.

---

## Core Architecture: Weight-Based Congress Engagement

### Weight & Complexity Scale (1-9)

Sovern routes prompts based on **weight**—a measure of prompt complexity, relational richness, and ethical weight:

#### **1.0 - 2.9: SIMPLE Prompt** 
- **Definition**: Straightforward factual query, surface-level question
- **Congress Strategy**: `direct` — No Congress debate required
- **Execution**: Single Paradigm call → Internal Logic/Beliefs/Memory routing
- **Example Queries**: 
  - "What is the capital of France?"
  - "How do photosynthesis work?" 
  - "Explain market equilibrium"
- **Response Pattern**: Swift, direct answer from knowledge domain
- **Memory Recording**: Simple interaction logged, minimal learning vectors

---

#### **3.0 - 5.9: MODERATE Complexity**
- **Definition**: Query touches relational, ethical, or personal domains; requires perspective synthesis
- **Congress Strategy**: `singleDebate` — One Congress call with all three perspectives
- **Execution**: 
  1. **Single Congress Call**: Advocate, Skeptic, and Synthesizer deliberate simultaneously
  2. **Candidate Responses**: Multiple drafts generated and evaluated
  3. **Selection**: Best response chosen based on coherence with beliefs
- **Example Queries**:
  - "How should I handle a difficult colleague?"
  - "Is it okay to prioritize my needs over others?"
  - "What does authentic friendship mean?"
- **Response Pattern**: Balanced perspective showing multiple angles, then synthesis
- **Memory Recording**: Human insights extracted, self insights about relational reasoning captured

---

#### **6.0 - 9.0: COMPLEX Engagement**
- **Definition**: Heavily weighted prompt—ethical dilemmas, profound uncertainty, high relational/personal stakes
- **Congress Strategy**: `multiCall` — Four sequential Congress calls for robust deliberation
- **Execution**:
  1. **Call 1: Advocate** → Makes strongest structured argument for proposed path
  2. **Call 2: Skeptic** → Provides structured rebuttal with identified risks/concerns
  3. **Call 3: Synthesizer** → Reconciles tensions; finds integrative solution
  4. **Call 4: Final Paradigm** → Runs ALL THREE perspectives again to test robustness and identify remaining tensions
- **Candidate Responses**: Heavy iteration, multiple rejections with explicit reasoning
- **Selection**: Response emerges from robust, multi-perspective deliberation
- **Example Queries**:
  - "I'm considering leaving a long-term relationship, but I'm scared. Help me think through this."
  - "How do I balance being honest with my best friend AND being kind when they're struggling?"
  - "I feel like I'm failing at life. How do I rebuild trust in myself?"
- **Response Pattern**: Multi-layered wisdom—showing internal debate, identified tensions, integrated perspective
- **Memory Recording**: Deep self insights about own reasoning patterns, belief alignment points, reasoning strength/weakness

---

## Data Model: `LogicEntry`

```swift
struct LogicEntry: Codable, Identifiable {
    let id: UUID                                  // Unique identifier
    let timestamp: Date                           // When debate occurred
    let userQuery: String                         // Original question
    
    let weight: Double                            // 1-9 scale (bounded)
    let complexityCategory: ComplexityCategory   // simple | moderate | complex
    let paradigmRouting: String                  // Strategy selected (e.g., "analytical", "empathetic")
    
    let engagementStrategy: CongressEngagementStrategy  // direct | singleDebate | multiCall
    let congressCallSequence: [Int]              // Which calls made: [] | [1] | [1,2,3,4]
    var perspectivesByCall: [[CongressPerspective]]    // Perspectives grouped by call
    
    var reasoningSteps: [ReasoningStep]          // Timeline of analysis
    var candidateResponses: [CandidateResponse]  // Draft iterations
    var profoundInsights: [String]               // Emergent truths (tagged ✨)
    
    let finalResponse: String                    // Selected response delivered
    let finalReasoning: String                   // WHY this response chosen
}
```

### Property Semantics

| Property | Purpose | Rules |
|----------|---------|-------|
| `weight` | Complexity measurement | 1-9, bounded. Calculated by Paradigm before LogicEntry creation. |
| `complexityCategory` | Inferred from weight | Simple (1-2.9), Moderate (3-5.9), Complex (6-9). Auto-set in init. |
| `paradigmRouting` | Response strategy | String: "analytical", "empathetic", "socratic", "exploratory", etc. User-facing. |
| `engagementStrategy` | Congress involvement level | Determined by complexityCategory. Auto-set. |
| `congressCallSequence` | Which Congress calls made | [] (direct), [1] (single debate), [1,2,3,4] (multi-call). |
| `perspectivesByCall` | Debate organized by call | Array of arrays, indexed by call number (0-3 for calls 1-4). |
| `reasoningSteps` | Real-time analysis log | Timeline of `analysis` → `concern` → `debate` → `insight` → `revision`. |
| `candidateResponses` | Response drafting process | Numbered drafts with status (rejected/selected/considering) and rejection reasons. |
| `profoundInsights` | Emergent discoveries | Insights tagged with ✨; extracted during reasoning or perspective synthesis. |

---

## Congress Perspectives: The Four Voices

Each perspective represents a distinct reasoning stance:

### **Advocate** 🎯
- **Role**: Makes strongest case for proposed path; supports user/idea
- **Reasoning Style**: Optimistic, possibility-focused, building on strengths
- **Position Example**: "This relationship has deep roots and shared values. Building on them is worth effort."
- **Contribution**: Identifies what's worth preserving and pursuing

### **Skeptic** ⚠️
- **Role**: Questions assumptions; identifies risks, concerns, pitfalls
- **Reasoning Style**: Risk-aware, critically examining weaknesses
- **Position Example**: "But patterns show this dynamic is repeating. Without change, hope is delusional."
- **Contribution**: Prevents rushed decisions; surfaces real constraints

### **Synthesizer** 🔗
- **Role**: Finds common ground; integrative solutions
- **Reasoning Style**: Systems-thinking, seeking elegant bridges between positions
- **Position Example**: "Both views hold truth. The question isn't either/or, but how to honor both values."
- **Contribution**: Moves beyond debate to integrated action

### **Ethics** ⚖️
- **Role**: Evaluates alignment with core values and impact
- **Reasoning Style**: Value-grounded, checking integrity
- **Position Example**: "Our Authenticity belief means being honest with yourself. Staying without growth dishonors that."
- **Contribution**: Ensures decisions align with who Sovern is

---

## Reasoning Steps: Real-Time Timeline

Reasoning unfolds as timestamped steps:

```swift
enum ReasoningStepType: String {
    case analysis   // 🔍 Initial problem decomposition
    case concern    // ⚠️ Risks or tensions identified
    case debate     // 💬 Perspectives in conversation
    case insight    // ✨ Emergent truth discovered
    case revision   // 🔄 Original reasoning revised with new understanding
}
```

### Typical Flow

For a **moderate complexity** query, steps might be:
1. **analysis**: "Query touches relational domain + personal values → Congress needed"
2. **analysis**: "Core tension: fear vs. growth"
3. **debate**: "Advocate emphasizes connection possibility"
4. **debate**: "Skeptic raises pattern concern"
5. **debate**: "Synthesizer finds path that honors both"
6. **insight**: "Real question isn't whether to stay, but whether to grow together"
7. **revision**: "Original framing (stay vs. leave) revised to (transform vs. end)"

For **complex** queries, steps spread across multiple Congress calls:
- Call 1 steps: Advocate's structured argument
- Call 2 steps: Skeptic's rebuttal, new concerns raised
- Call 3 steps: Synthesizer's integration
- **insight** (critical): "Both positions have merit; AND there's a third path"
- Call 4 steps: Final test of integrated position

---

## Response Drafting: Iteration & Selection

Candidate responses show Sovern's iterative thinking:

```swift
struct CandidateResponse: Codable {
    let draftNumber: Int          // 1, 2, 3, etc.
    let content: String           // Draft text
    let status: ResponseStatus    // rejected | selected | considering
    let rejectionReason: String?  // WHY draft was rejected
    let timestamp: Date
}
```

### Rejection Rationale (Examples)

| Draft | Content Excerpt | Status | Rejection Reason |
|-------|-----------------|--------|------------------|
| Draft 1 | "You should just leave..." | rejected | Too decisive; dismisses emotional depth. Not honoring relational value. |
| Draft 2 | "Stay if you're comfortable..." | rejected | Avoids hard truth. Enables avoidance. Inauthentic. |
| Draft 3 | "Real growth requires hard conversations..." | selected | Holds both honesty AND compassion. Aligns with Authenticity + Empathy. |

**Key Pattern**: Rejection reasons are explicit. This transparency shows Sovern evaluating its own thinking in real-time.

---

## Profound Insights: Emergent Truths

When Congress deliberation produces a truth bigger than the original question, it's tagged as a profound insight:

```swift
mutating func addProfoundInsight(_ insight: String) {
    profoundInsights.append("✨ " + insight)
}
```

### Examples

- **From question about relationship**: "✨ Authentic care includes honest challenge, not just emotional validation"
- **From question about self-worth**: "✨ Shame thrives in silence; stating the fear aloud weakens its power"
- **From question about boundaries**: "✨ True intimacy requires being fully known, including vulnerabilities"

**Display Rule**: In Logic tab, insights highlighted with ✨ emoji and displayed prominently.

---

## Logic Library: Collection Manager

```swift
class LogicLibrary: ObservableObject {
    @Published var entries: [LogicEntry] = []
    
    // Query methods
    func entries(for userQuery: String) -> [LogicEntry]
    func entry(withId id: UUID) -> LogicEntry?
    func entries(in category: ComplexityCategory) -> [LogicEntry]
    func entries(with strategy: CongressEngagementStrategy) -> [LogicEntry]
    func entries(from start: Date, to end: Date) -> [LogicEntry]
    
    // Analysis
    var statistics: LogicLibraryStatistics
    var entriesSorted: [LogicEntry]  // By timestamp, newest first
    var mostRecentEntry: LogicEntry?
    
    // Persistence
    func exportAsJSON() -> Data?
    func importFromJSON(_ data: Data) throws
}
```

### Key Statistics Tracked

```swift
struct LogicLibraryStatistics {
    let totalEntries: Int
    let simpleCount: Int                      // How many direct responses
    let moderateCount: Int                    // How many single debates
    let complexCount: Int                     // How many multi-call sequences
    let averageWeight: Double                 // Average prompt complexity
    let totalCongressCalls: Int               // Total calls made across all entries
    let totalPerspectivesRecorded: Int        // Count of all perspective deliberations
    let averageResponseDrafts: Double         // How much iteration typical
    let mostCommonParadigm: String?           // Which routing strategy used most
}
```

---

## Architecture Constraints

### Congress Engagement Rules

1. **Never fake debate**: If `engagementStrategy == .direct`, perspectives array is empty
2. **All calls logged**: If multi-call sequence, all 4 calls recorded with timestamps
3. **Weight → Strategy is deterministic**: Given weight, strategy is automatically assigned
4. **Bounded weight**: Weight always 1-9; no silent overflow

### Reasoning Integrity

1. **Timestamped progression**: Reasoning steps capture actual temporal sequence
2. **Rejection reasoning required**: Every rejected candidate response must have rationale
3. **No step without reason**: Analysis/insight steps include content (not skeleton logging)
4. **Revision pairs**: If type == `.revision`, both original and revised reasoning included

### Backend Synchronization

| iOS Property | Python Field | Sync Direction | Timing |
|--------------|--------------|-----------------|---------|
| `paradigmRouting` | `paradigm_state` | Bidirectional | Immediately after routing decision |
| `engagementStrategy` + `perspectivesByCall` | `congress_state` | Bidirectional | Immediately after Congress completes |
| `reasoning Steps` | `logic_timeline` | iOS → Python | After debate log finalized |
| `profoundInsights` | `emergent_truths` | iOS → Python | When insight extracted |

---

## SwiftUI Integration Patterns

### Using LogicEntry in Views

```swift
@ObservedObject var logicLibrary: LogicLibrary

var body: some View {
    VStack {
        // Display most recent entry
        if let entry = logicLibrary.mostRecentEntry {
            Text("Weight: \(entry.weight, specifier: "%.1f")")
            Text(entry.weightExplanation)  // User-friendly summary
            
            // Show Congress engagement status
            if entry.congressEngaged {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Congress Engaged: \(entry.congressCallCount) calls")
                }
            }
            
            // Show reasoning timeline
            ForEach(entry.reasoningSteps) { step in
                HStack {
                    Text(step.type.emoji)
                    Text(step.content)
                    Text(step.timestamp.formatted(date: .omitted, time: .standard))
                }
            }
            
            // Show perspectives by call
            ForEach(Array(entry.perspectivesByCall.enumerated()), id: \.offset) { callIndex, perspectives in
                VStack(alignment: .leading) {
                    Text("Congress Call \(callIndex + 1)")
                        .font(.headline)
                    
                    ForEach(perspectives) { perspective in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(perspective.role.emoji)
                                Text(perspective.role.rawValue)
                                    .font(.headline)
                                Spacer()
                                Text("\(perspective.strengthOfArgument, specifier: "%.1f")/10")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(perspective.position)
                                .font(.subheadline)
                            Text(perspective.reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Show candidate responses
            VStack(alignment: .leading) {
                Text("Response Development")
                    .font(.headline)
                ForEach(entry.candidateResponses) { candidate in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Draft \(candidate.draftNumber)")
                                .font(.subheadline)
                            Spacer()
                            Text(candidate.status.emoji)
                        }
                        if candidate.status == .rejected, let reason = candidate.rejectionReason {
                            Text("Rejected: \(reason)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(candidate.status == .selected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Show profound insights
            if !entry.profoundInsights.isEmpty {
                VStack(alignment: .leading) {
                    Text("Profound Insights")
                        .font(.headline)
                    ForEach(entry.profoundInsights, id: \.self) { insight in
                        Text(insight)
                            .font(.body)
                            .italic()
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}
```

### Creating a LogicEntry

```swift
// In ChatManager or similar
func processQuery(_ userQuery: String) {
    // 1. Determine weight (algorithm TBD - could use word count, semantic analysis, etc.)
    let weight = determineWeight(for: userQuery)  // Returns 1-9
    
    // 2. Select routing strategy
    let routing = selectParadigmRouting(for: userQuery)  // "analytical", "empathetic", etc.
    
    // 3. Create LogicEntry (engagementStrategy auto-set from weight)
    var logicEntry = LogicEntry(
        userQuery: userQuery,
        weight: weight,
        paradigmRouting: routing
    )
    
    // 4. Add reasoning steps as analysis unfolds
    logicEntry.addReasoningStep(
        ReasoningStep(type: .analysis, content: "Query classified as \(logicEntry.complexityCategory.rawValue)")
    )
    
    // 5. If Congress engaged...
    if logicEntry.congressEngaged {
        // Gather perspectives
        for callNumber in logicEntry.congressCallSequence {
            let perspectives = conductCongressCall(callNumber, for: userQuery)
            for perspective in perspectives {
                logicEntry.addPerspective(perspective)
            }
        }
        
        // Add reasoning steps from Congress
        logicEntry.addReasoningStep(
            ReasoningStep(type: .debate, content: "Congress deliberated on relational and ethical dimensions")
        )
    }
    
    // 6. Generate candidate responses
    var draftNumber = 1
    for candidate in generateCandidates(logicEntry) {
        var response = CandidateResponse(
            draftNumber: draftNumber,
            content: candidate.text,
            status: .considering
        )
        
        // Evaluate candidate
        if !isCoherentWithBeliefs(candidate, beliefs: beliefSystem.beliefs) {
            response.rejectionReason = "Doesn't align with core Authenticity belief"
            response.status = .rejected
        } else {
            response.status = .selected
        }
        
        logicEntry.addCandidateResponse(response)
        draftNumber += 1
    }
    
    // 7. Extract profound insights
    if let insight = extractProfoundInsight(from: logicEntry) {
        logicEntry.addProfoundInsight(insight)
    }
    
    // 8. Finalize
    let selectedResponse = logicEntry.candidateResponses.first { $0.status == .selected }!.content
    logicEntry.finalize(
        response: selectedResponse,
        reasoning: "Selected for coherence with beliefs and relational authenticity"
    )
    
    // 9. Record
    logicLibrary.add(logicEntry)
}
```

---

## Testing Examples

### Test Case 1: Simple Query

```swift
func testSimpleQueryRouting() {
    let entry = LogicEntry(
        userQuery: "What is photosynthesis?",
        weight: 1.5,
        paradigmRouting: "informational"
    )
    
    XCTAssertEqual(entry.complexityCategory, .simple)
    XCTAssertEqual(entry.engagementStrategy, .direct)
    XCTAssertTrue(entry.congressCallSequence.isEmpty)
    XCTAssertTrue(entry.perspectivesByCall.isEmpty)
}
```

### Test Case 2: Moderate Query with Congress

```swift
func testModerateQueryCongress() {
    var entry = LogicEntry(
        userQuery: "Should I prioritize career or family?",
        weight: 4.2,
        paradigmRouting: "reflective"
    )
    
    XCTAssertEqual(entry.complexityCategory, .moderate)
    XCTAssertEqual(entry.engagementStrategy, .singleDebate)
    XCTAssertEqual(entry.congressCallSequence, [1])
    XCTAssertEqual(entry.perspectivesByCall.count, 1)
    
    // Add perspectives
    entry.addPerspective(CongressPerspective(
        role: .advocate,
        position: "Career builds identity and impact",
        reasoning: "Professional growth fulfills potential",
        callNumber: 1
    ))
    
    entry.addPerspective(CongressPerspective(
        role: .skeptic,
        position: "Career can become consuming",
        reasoning: "Time invested in work is time away from loved ones",
        callNumber: 1
    ))
    
    entry.addPerspective(CongressPerspective(
        role: .synthesizer,
        position: "Seek work-life integration, not balance",
        reasoning: "Find career that enables family time",
        callNumber: 1
    ))
    
    XCTAssertEqual(entry.perspectivesByCall[0].count, 3)
    XCTAssertTrue(entry.congressEngaged)
}
```

### Test Case 3: Complex Multi-Call

```swift
func testComplexMultiCallSequence() {
    var entry = LogicEntry(
        userQuery: "I'm having thoughts of leaving my marriage, but there's so much history...",
        weight: 7.8,
        paradigmRouting: "compassionate"
    )
    
    XCTAssertEqual(entry.complexityCategory, .complex)
    XCTAssertEqual(entry.engagementStrategy, .multiCall)
    XCTAssertEqual(entry.congressCallSequence, [1, 2, 3, 4])
    XCTAssertEqual(entry.perspectivesByCall.count, 4)
    
    // Simulate four Congress calls
    for callNum in 1...4 {
        if callNum == 1 {
            // Call 1: Advocate builds strongest case for leaving
            entry.addPerspective(CongressPerspective(
                role: .advocate,
                position: "Life is too short for unfulfilling relationships",
                reasoning: "Personal happiness is a valid basis for major decisions",
                callNumber: callNum
            ))
        } else if callNum == 2 {
            // Call 2: Skeptic questions that reasoning
            entry.addPerspective(CongressPerspective(
                role: .skeptic,
                position: "Leaving creates new pain and loss",
                reasoning: "Shared history and mutual vulnerabilities at stake",
                callNumber: callNum
            ))
        } else if callNum == 3 {
            // Call 3: Synthesizer finds integration
            entry.addPerspective(CongressPerspective(
                role: .synthesizer,
                position: "Real question isn't stay vs. leave, but grow vs. stagnate",
                reasoning: "Some relationships end; others transform. First, try transformation.",
                callNumber: callNum
            ))
        } else {
            // Call 4: Final test—all three again
            entry.addPerspective(CongressPerspective(
                role: .advocate,
                position: "Growth together is possible IF both commit",
                reasoning: "Synthesizer's path is harder, but aligns with values",
                callNumber: callNum
            ))
        }
    }
    
    XCTAssertEqual(entry.perspectivesByCall[0].count, 1)  // Call 1: Advocate
    XCTAssertEqual(entry.perspectivesByCall[1].count, 1)  // Call 2: Skeptic
    XCTAssertEqual(entry.perspectivesByCall[2].count, 1)  // Call 3: Synthesizer
    XCTAssertEqual(entry.perspectivesByCall[3].count, 1)  // Call 4: Advocate again
    
    XCTAssertEqual(entry.allPerspectives.count, 4)
    XCTAssertEqual(entry.congressCallCount, 4)
}
```

---

## Next Steps: Integration

1. **ChatManager** will calculate weight and create LogicEntry for each user query
2. **LogicDetailView** will display the complete reasoning timeline (steps, perspectives, candidates, insights)
3. **Memory Learning** will extract `selfInsights` by analyzing Congress patterns
4. **Belief Updates** will be triggered by profound insights and Congress conclusions
5. **Backend Sync** will send paradigm_state, congress_state to Python for cognitive state tracking

---

## Key Patterns to Preserve

✅ **Congress integrity**: Never fake debate; always respect the weight → strategy mapping  
✅ **Timestamped auditability**: Every step, perspective, and revision has a timestamp  
✅ **Reasoning transparency**: Rejection reasons and revision explanations visible to user  
✅ **Coherence checking**: Response selection validates alignment with beliefs  
✅ **Self-reference**: Profound insights flow into memory learning, then belief updates
