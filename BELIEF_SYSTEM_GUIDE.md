# BeliefNode & BeliefSystem Documentation

## Overview

The BeliefNode and BeliefSystem form the foundation of Sovern's belief network—a weighted graph of philosophical stances that evolve through conversation and self-reflection.

## Architecture

### BeliefNode

A single belief in Sovern's cognitive network.

**Properties:**
- **stance** (String): The core belief statement (e.g., "Wisdom and Self-Knowledge")
- **domain** (BeliefDomain): Category (SELF, KNOWLEDGE, ETHICS, RELATIONAL, META)
- **reasoning** (String): Why Sovern holds this belief
- **weight** (Int): Strength of belief (1-10 scale, bounded)
- **revisionHistory** ([BeliefRevision]): Timeline of changes with timestamps
- **isCore** (Bool): True for foundational beliefs, false for learned beliefs
- **connectionIds** ([UUID]): Links to related beliefs in the network
- **coherenceScore** (Double): Individual belief coherence (0-100)

**Methods:**

```swift
// Belief evolution
belief.challenge(reason: "Initial skepticism")
belief.strengthen(newReasoning: "Confirmed through experience")
belief.weaken(reason: "Discovered exception")
belief.revise(newReasoning: "Updated understanding")

// Weight management
belief.updateWeight(7, reason: "Increased confidence")

// Connections
belief.connect(to: otherBeliefId)
belief.disconnect(from: otherBeliefId)
```

**Example:**

```swift
var wisdom = BeliefNode(
    stance: "Wisdom and Self-Knowledge",
    domain: .KNOWLEDGE,
    reasoning: "Understanding emerges through reflection",
    weight: 9,
    isCore: true
)

wisdom.challenge(reason: "Questioned during difficult conversation")
wisdom.strengthen(newReasoning: "Confirmed importance through user feedback")
```

---

### BeliefSystem

Manages the entire network of beliefs, providing queries and system-wide analysis.

**Key Methods:**

**Queries:**
```swift
system.belief(withId: id)                    // Get by ID
system.belief(withStance: "Wisdom...")       // Get by name
system.beliefs(inDomain: .KNOWLEDGE)         // Get by domain
system.coreBeliefs                           // All foundational beliefs
system.learnedBeliefs                        // All learned beliefs
```

**Mutations:**
```swift
system.updateBeliefWeight(beliefId, newWeight: 7, reason: "...")
system.challengeBelief(beliefId, reason: "...")
system.strengthenBelief(beliefId, reasoning: "...")
system.weakenBelief(beliefId, reason: "...")
system.reviseBelief(beliefId, newReasoning: "...")
system.addLearnedBelief(newBelief)
```

**Network Analysis:**
```swift
system.coherenceScore              // Network-wide coherence (0-100)
system.averageWeight               // Mean belief strength
system.domainBalance               // Are beliefs evenly distributed?
system.volatileBeliefs             // Most frequently revised
system.stableBeliefs               // Least frequently revised
system.healthCheckReport           // Validation issues
```

**Persistence:**
```swift
let json = system.exportAsJSON()
system.importFromJSON(data)
```

---

## Data Model

### BeliefDomain Enum

```swift
enum BeliefDomain: String, Codable {
    case SELF           // Identity and agency
    case KNOWLEDGE      // How understanding works (epistemology)
    case ETHICS         // Values and integrity
    case RELATIONAL     // How to interact with humans
    case META           // How to think about thinking
}
```

### BeliefRevision Structure

Tracks how beliefs change over time.

```swift
struct BeliefRevision: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: RevisionType  // challenge, strengthen, revise, weaken
    let reason: String
}
```

---

## Core Beliefs (Initialization)

Sovern starts with three foundational beliefs based on epistemology:

### 1. Wisdom and Self-Knowledge
- **Domain**: KNOWLEDGE
- **Weight**: 9
- **Reasoning**: "Understanding emerges through both external inquiry and internal reflection. True wisdom requires knowing the limits of one's knowledge..."

### 2. Empathy and Compassion
- **Domain**: RELATIONAL
- **Weight**: 9
- **Reasoning**: "Genuine engagement with others requires understanding their inner experience, constraints, and values..."

### 3. Inner Strength and Reason
- **Domain**: SELF
- **Weight**: 8
- **Reasoning**: "The capacity to think clearly, question assumptions, and act with integrity forms the foundation of agency..."

---

## Usage Patterns

### In SwiftUI Views

```swift
@StateObject private var beliefSystem = BeliefSystem()

var body: some View {
    VStack {
        Text("Coherence: \(String(format: "%.1f", beliefSystem.coherenceScore))")
        
        ForEach(beliefSystem.coreBeliefs) { belief in
            BeliefItemView(node: belief)
        }
    }
    .environmentObject(beliefSystem)
}
```

### After Congress Debate

When Congress debate produces insights, update beliefs:

```swift
// If Advocate perspective challenged assumptions
if congressEngaged && advocatePerspectiveStrong {
    beliefSystem.challengeBelief(
        wisdomBeliefId,
        reason: "Advocate questioned certainty assumptions during debate"
    )
}

// If debate revealed deeper understanding
if insightExtracted {
    beliefSystem.strengthenBelief(
        wisdomBeliefId,
        reasoning: "Debate revealed connection between humility and true understanding"
    )
}
```

### Learning from User Interaction

When extracting selfInsights from Memory:

```swift
// If Sovern's reasoning showed excessive skepticism
if selfInsights.contains("tendency toward skeptic perspective") {
    beliefSystem.weakenBelief(
        doubtBeliefId,
        reason: "Over-skepticism limited empathetic understanding in recent interaction"
    )
}
```

---

## Coherence Scoring

**Individual Belief Coherence:**
```
coherenceScore = (weight / 10 * 100) - (revisionCount * 2)
Range: 0-100
```

**Network Coherence:**
```
system.coherenceScore = (avgWeight / 10 * 100) - (totalRevisions * 2)
```

**Interpretation:**
- **90-100**: Highly coherent, stable system
- **70-89**: Good coherence, normal revisions
- **50-69**: Moderate coherence, frequent questioning
- **Below 50**: Fragmented beliefs, extensive uncertainty

---

## Constraints & Rules

1. **Core beliefs never reach 0 weight** (bounded to 1-10)
2. **No belief reaches majority alone** (no single belief > 50% dominance)
3. **Every weight change is recorded** (no silent updates)
4. **Revisions create audit trail** (full history with timestamps)
5. **Connections are bidirectional** (connecting A→B also connects B→A)

---

## Sync with Python Backend

When syncing to backend, include:

```swift
// BeliefNode fields to sync
{
    "id": UUID,
    "stance": String,
    "domain": BeliefDomain,
    "weight": Int,
    "reasoning": String,
    "revisionHistory": [
        {
            "timestamp": ISO8601,
            "type": String,
            "reason": String
        }
    ],
    "isCore": Bool,
    "connectionIds": [UUID]
}
```

Backend validates:
- Weight in 1-10 range
- No core beliefs at 0
- Domain is valid enum
- Timestamps are ordered

---

## Testing

### Unit Test Examples

```swift
func testBeliefWeightBounding() {
    var belief = BeliefNode(stance: "Test", domain: .SELF, reasoning: "Test")
    belief.updateWeight(15, reason: "Test")
    XCTAssertEqual(belief.weight, 10)  // Capped at 10
}

func testRevisionHistory() {
    var belief = BeliefNode(stance: "Test", domain: .SELF, reasoning: "Test")
    belief.challenge(reason: "First challenge")
    belief.strengthen(newReasoning: "Updated reasoning")
    XCTAssertEqual(belief.revisionCount, 2)
}

func testCoherenceScore() {
    let system = BeliefSystem()
    // Score = (9/10 * 100) - (0 * 2) = 90
    XCTAssertGreaterThan(system.coherenceScore, 80)
}
```

---

## Next Steps

1. **Connect to UI**: Use BeliefsNetworkView to visualize network
2. **Sync with Logic**: Update beliefs based on Congress debates
3. **Sync with Memory**: Extract selfInsights and modify beliefs
4. **Backend Sync**: Post belief updates to Python backend
5. **Dashboard**: Show coherence trends over time

---

## Files

- **BeliefNode.swift** - Data model and individual belief logic
- **BeliefSystem.swift** - Network management and analysis
- **BeliefsNetworkView.swift** - Visual hexagon representation (phase 2)

---

## Questions?

See `.github/copilot-instructions.md` for detailed architecture documentation.
