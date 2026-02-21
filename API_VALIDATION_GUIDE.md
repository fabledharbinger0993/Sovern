# API & Interface Validation Guide

## Overview

This document validates the interfaces between all systems and confirms API consistency. The "API" here refers to the method signatures and data flow contracts between systems (not REST APIs—that's Phase 3).

---

## System Interfaces

### 1. Chat → Logic → Memory Flow (Core Loop)

```
ChatManager.addUserMessage(query)
    ↓
Paradigm.determineWeight(query) → weight: Double (1-9)
    ↓
LogicEntry(weight) → auto-sets: complexityCategory, engagementStrategy
    ↓
Congress.engage() → creates: CongressPerspective[], ReasoningStep[]
    ↓
LogicEntry.finalize() → sets: finalResponse, finalReasoning
    ↓
MemoryEntry.extract() → analyzes Congress, creates: HumanInsights[], SelfInsights[]
    ↓
ChatMessage.linkToLogic(logicId)
ChatMessage.linkToMemory(memoryId)
```

### 2. BeliefSystem Interface

**Mutation Entry Points**:
```swift
beliefSystem.updateBeliefWeight(beliefId: UUID, newWeight: Double)
beliefSystem.challenge(beliefId: UUID, reason: String)
beliefSystem.strengthen(beliefId: UUID, reason: String)
beliefSystem.weaken(beliefId: UUID, reason: String)
beliefSystem.revise(beliefId: UUID, newReasoning: String, revisionReason: String)
```

**All mutations**:
- Bounded: Weight always 1-10
- Timestamped: Revision recorded with timestamp
- Auditable: Reason always required
- Coherence-aware: Update triggers coherenceScore recalculation

**Query Entry Points**:
```swift
beliefSystem.belief(withId: UUID) → BeliefNode?
beliefSystem.belief(withStance: String) → BeliefNode?
beliefSystem.beliefs(inDomain: BeliefDomain) → [BeliefNode]
beliefSystem.coreBeliefs → [BeliefNode]  // The 3 epistemological beliefs
beliefSystem.learnedBeliefs → [BeliefNode]
beliefSystem.coherenceScore → Double (0-100)
```

**Network Operations**:
```swift
beliefSystem.connect(_ id1: UUID, to id2: UUID)      // Bidirectional
beliefSystem.disconnect(_ id1: UUID, from id2: UUID) // Bidirectional
```

---

### 3. LogicLibrary Interface

**Record Entry Points**:
```swift
logicLibrary.add(_ entry: LogicEntry)
logicLibrary.entry(withId: UUID) → LogicEntry?
```

**Query Entry Points**:
```swift
logicLibrary.entries(for userQuery: String) → [LogicEntry]
logicLibrary.entries(in category: ComplexityCategory) → [LogicEntry]
logicLibrary.entries(with strategy: CongressEngagementStrategy) → [LogicEntry]
logicLibrary.entries(from: Date, to: Date) → [LogicEntry]
logicLibrary.mostRecentEntry → LogicEntry?
logicLibrary.entriesSorted → [LogicEntry]
```

**Statistics**:
```swift
logicLibrary.statistics → LogicLibraryStatistics
  // Includes: complexity distribution, Congress usage, average weight, paradigm usage
```

---

### 4. RelationalMemory Interface

**Record Entry Points**:
```swift
memory.add(_ entry: MemoryEntry)
memory.entry(withId: UUID) → MemoryEntry?
memory.entry(linkedToLogicId: UUID) → MemoryEntry?
```

**Human Insight Queries**:
```swift
memory.allHumanInsights → [Insight]
memory.humanInsights(by: InsightCategory) → [Insight]
memory.humanValuesIdentified() → [Insight]
memory.communicationPatternsObserved() → [Insight]
memory.mostCommonHumanInsightCategory → InsightCategory?
```

**Self Insight Queries**:
```swift
memory.allSelfInsights → [Insight]
memory.selfInsights(by: InsightCategory) → [Insight]
memory.reasoningPatternsDiscovered() → [Insight]
memory.growthAreasIdentified() → [Insight]
memory.beliefAlignmentInsights() → [(beliefId: UUID?, count: Int)]
memory.mostCommonSelfInsightCategory → InsightCategory?
```

**Pattern Queries**:
```swift
memory.allLearnedPatterns → [LearnedPattern]
memory.patternsRankedByFrequency → [LearnedPattern]
memory.patterns(relatedToBelief: UUID) → [LearnedPattern]
```

**Reflection Methods**:
```swift
memory.deeplyReflectiveEntries → [MemoryEntry]  // selfInsights.count >= 2
memory.richLearningEntries → [MemoryEntry]      // Multiple insight categories
```

---

### 5. ChatManager Interface

**Message Operations**:
```swift
chatManager.addUserMessage(_ content: String) → ChatMessage
chatManager.addSovernMessage(_ content: String, logicEntryId: UUID?, memoryEntryId: UUID?, tokens: Int) → ChatMessage
chatManager.startTyping()
chatManager.updateTypingMessage(_ content: String)
chatManager.finishTyping(logicEntryId: UUID?, memoryEntryId: UUID?, tokens: Int)
```

**Linking Operations**:
```swift
chatManager.linkToLogic(messageId: UUID, logicId: UUID)
chatManager.linkToMemory(messageId: UUID, memoryId: UUID)
```

**Query Operations**:
```swift
chatManager.userMessages() → [ChatMessage]
chatManager.sovernMessages() → [ChatMessage]
chatManager.messages(from: Date, to: Date) → [ChatMessage]
chatManager.mostRecentUserMessage → ChatMessage?
chatManager.mostRecentSovernMessage → ChatMessage?
chatManager.messagesWithLogicEntries() → [ChatMessage]
chatManager.messagesWithMemoryEntries() → [ChatMessage]
chatManager.fullyLinkedMessages → [ChatMessage]
```

**Copy Operations**:
```swift
chatManager.copyMessage(withId: UUID) → String?  // Formatted with role, emoji, timestamp
chatManager.copyConversation() → String
chatManager.copyUserMessages() → String
chatManager.copyConversationAsJSON() → String?
```

**Search**:
```swift
chatManager.search(for: String) → [ChatMessage]
chatManager.conversationExcerpt(around: UUID, contextSize: Int) → [ChatMessage]
```

---

## Cross-System Data Contracts

### Chat ↔ Logic Contract

**When ChatMessage is created with user content**:
| Responsibility | System | Action |
|---|---|---|
| Accept query | ChatManager | Store ChatMessage with role = .user |
| Analyze weight | Paradigm | Call `determineWeight(query)` → Double (1-9) |
| Create Logic entry | LogicEntry | `init(userQuery, weight, paradigmRouting)` auto-sets category & strategy |
| Run Congress (if needed) | Congress | Populate`perspectives[]`, `reasoningSteps[]` based on strategy |
| Extract insights | Memory | Analyze Congress & create `humanInsights[]`, `selfInsights[]` |
| Link back | ChatManager | Call `linkToLogic(messageId, logicId)` and `linkToMemory(messageId, memoryId)` |

**Invariants**:
- Every Sovern message (role = .assistant) MUST have `logicEntryId` set
- Every Sovern message MUST have `memoryEntryId` set after memory extraction
- Timestamps MUST match across Chat, Logic, Memory for audit trail

### Logic → Belief Contract

**When profound insights or Congress conclusions emerge**:
| Item | Flow |
|------|------|
| Authority | LogicEntry has `profoundInsights[]` and Congress determined best path |
| Action | `BeliefSystem.revise(beliefId, newReasoning, revisionReason: "Congress insight: ...")` |
| Record | BeliefNode creates `BeliefRevision` with timestamp and reasoning |
| Impact | `coherenceScore` recalculated; network updated |
| Frequency | Once per interaction (after Logic finalizes) |

**Weight Update Rules**:
- Simple queries (direct) → Beliefs unchanged (no Congress, no insight)
- Moderate queries (single debate) → Beliefs updated only if profound insight
- Complex queries (multi-call) → Higher chance of belief revision (deeper deliberation)

### Memory → Belief Contract

**When self-insights identify growth areas or reasoning patterns**:
| Item | Flow |
|------|------|
| Detection | RelationalMemory extracts `selfInsights` with category = `.growthArea` or `.reasoningPattern` |
| Trigger | If frequency of pattern > threshold (e.g., 3+ instances), mark for belief review |
| Action | Optional: `BeliefSystem.weaken(beliefId, reason: "Pattern identified: ...")` to signal growth area |
| Feedback | User sees in Memory tab: "Pattern discovered" + related beliefs affected |

---

## API Validation Checklist

### ✅ Consistency Checks

- [x] **Timestamps**: All entries (Chat, Logic, Memory, Belief revisions) use `Date` for consistency
- [x] **IDs**: All entities use `UUID` + conform to `Identifiable`
- [x] **Immutability**: Entity structs are immutable; managers use `@Published` for updates
- [x] **Codable**: All data models conform to `Codable` for persistence
- [x] **Observability**: All managers conform to `ObservableObject` with `@Published` properties

### ✅ Linking Integrity

- [x] **ChatMessage** → LogicEntry: Optional UUID field `logicEntryId`
- [x] **ChatMessage** → MemoryEntry: Optional UUID field `memoryEntryId`
- [x] **MemoryEntry** → LogicEntry: Optional UUID field `logicEntryId`
- [x] **BeliefRevision** → timestamps: All revisions timestamped for audit trail
- [x] **Insight** → related belief: Optional UUID field `relatedBeliefId` for belief linkage

### ✅ Constraint Enforcement

| Constraint | Enforced | Location |
|-----------|----------|----------|
| Weight 1-10 (belief) | Yes | `BeliefNode.updateWeight()` |
| Weight 1-9 (logic) | Yes | `LogicEntry.init()` |
| Frequency 0-1 (pattern) | Yes | `LearnedPattern.init()` |
| Confidence 0-1 (source) | Yes | `DataSource.init()` |
| No silent mutations | Yes | All mutations require reason parameter |

### ✅ Query Interface Coverage

| System | Query Type | Covered | Method |
|--------|-----------|---------|--------|
| BeliefSystem | By ID | ✓ | `belief(withId:)` |
| BeliefSystem | By stance | ✓ | `belief(withStance:)` |
| BeliefSystem | By domain | ✓ | `beliefs(inDomain:)` |
| LogicLibrary | By query text | ✓ | `entries(for:)` |
| LogicLibrary | By category | ✓ | `entries(in:)` |
| LogicLibrary | By time | ✓ | `entries(from:to:)` |
| RelationalMemory | By insight category | ✓ | `humanInsights(by:)`, `selfInsights(by:)` |
| RelationalMemory | By pattern frequency | ✓ | `patternsRankedByFrequency` |
| ChatManager | By message role | ✓ | `userMessages()`, `sovernMessages()` |
| ChatManager | By content | ✓ | `search(for:)` |

### ✅ Statistics Available

- [x] **BeliefSystem.statistics** → coherenceScore, domainBalance, volatility
- [x] **LogicLibrary.statistics** → complexity distribution, Congress usage, paradigm preference
- [x] **RelationalMemory.statistics** → insight counts, pattern frequency, learning velocity
- [x] **ChatManager.statistics** → message counts, token usage, linking integrity

---

## API Versioning Contract

### Current Version: 1.0

**Stable Interfaces** (won't change without major version bump):
- `ChatMessage` structure and role enum
- `BeliefNode` properties and mutation methods
- `LogicEntry` weight → complexity mapping (1-2.9 → simple, etc.)
- `MemoryEntry` human vs. self insight separation
- All manager query signatures

**Extensible** (can add without breaking):
- New InsightCategory values
- New CongressRole perspectives
- New ReasoningStepType variants
- New BeliefDomain categories

**Not stable yet** (pending refinement):
- Exact weighting algorithm for paradigm routing (may be tuned based on data)
- Threshold for "deeply reflective" entries (currently `selfInsights.count >= 2`)
- Pattern frequency threshold for belief review (not yet implemented)

---

## TestDataFactory Validation

Run this to validate all systems work together:

```swift
let issues = TestDataValidator.validateFullScenario()
issues.forEach { print($0) }

// Expected output:
// ✓ BeliefSystem: 6 beliefs (3 core + 3 learned)
// ✓ LogicLibrary: 3 entries (simple: 1, moderate: 1, complex: 1)
// ✓ RelationalMemory: 2 entries with X total insights
// ✓ ChatManager: 5 messages (user: 3, sovern: 2, linked: 2)
// ✓ Linking: All Sovern messages properly linked to Logic and Memory
```

---

## Next Steps: Visualization

With test data confirmed and APIs validated, ready to build:

1. **BeliefsNetworkView** — Hexagon visualization of belief network
2. **LogicDetailView** — Timeline of Congress debate with perspectives and reasoning steps
3. **MemoryViewTab** — Split view of human vs. self insights with pattern aggregation
4. **ChatView** — Message display with copy buttons

All views will use validated APIs to populate from test data, ensuring consistency.
