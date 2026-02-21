# Logic-Belief Integration Guide

## Overview

Sovern's **Advocate** and **Skeptic** perspectives now dynamically reference core beliefs, making arguments stronger as beliefs develop. This creates a growth loop: as Sovern's beliefs evolve through conversations, so does the quality of its Congress debate arguments.

## Architecture

### CongressPerspective Enhanced

```swift
struct CongressPerspective {
    // ... existing properties ...
    let linkedBeliefIds: [UUID]          // NEW: Beliefs informing this perspective
    
    func strengthenedWithBeliefs(_ beliefs: [BeliefNode]) -> Double
}
```

**Key Insight**: Advocate and Skeptic strength = 60% from aligned beliefs' weights + 40% from base argument strength

### Belief-Linked Perspectives

**Advocate Perspectives** (position support):
- Automatically link to beliefs supporting the proposed stance
- Strength increases as those beliefs' weights increase
- Example: If arguing for "growth mindset" (Advocate), links to SELF domain beliefs

**Skeptic Perspectives** (risk identification):  
- Link to beliefs highlighting caution, integrity, or boundary-setting
- Strength reflects conviction in protecting values
- Example: If identifying risks (Skeptic), links to ETHICS domain beliefs

**Synthesizer & Ethics**: 
- Don't automatically link beliefs (maintain objective mediation)
- Can be manually linked for transparency

## API Usage

### LogicLibrary Helper Methods

#### Link Beliefs to Existing Perspective

```swift
let beliefSystem = BeliefSystem()
let perspective = CongressPerspective(...)

let linkedPerspective = logicLibrary.linkBeliefsToPerspective(
    perspective,
    using: beliefSystem
)
// Returns perspective with linkedBeliefIds populated based on alignment
```

**How it works**:
1. Examines perspective's `position` and `reasoning` text
2. Matches against belief `stance` and `reasoning` keywords
3. Populates `linkedBeliefIds` with matching belief IDs

#### Strengthen Perspective Based on Beliefs

```swift
let strengthened = logicLibrary.strengthenPerspectiveWithBeliefs(
    perspective,
    using: beliefSystem
)
// Returns new perspective with updated strengthOfArgument
```

**Calculation**:
```
newStrength = (baseStrength × 0.4) + (avgBeliefWeight × 10 × 0.6)
bounds: 1-10
```

#### Create Advocate with Belief Leverage

```swift
let advocatePerspective = logicLibrary.createAdvocatePerspective(
    position: "Growth is possible despite setbacks",
    reasoning: "We have inner strength to overcome obstacles",
    strengthOfArgument: 7.5,
    callNumber: 1,
    beliefSystem: beliefSystem  // Automatic linking & strengthening
)
```

**What happens**:
1. Creates perspective with role = .advocate
2. Links it to relevant beliefs (matching "growth", "strength", etc.)
3. Strengthens it based on those beliefs' current weights
4. Returns ready-to-use perspective

#### Create Skeptic with Belief Caution

```swift
let skepticPerspective = logicLibrary.createSkepticPerspective(
    position: "Quick decisions risk missing important context",
    reasoning: "Wisdom requires careful consideration",
    strengthOfArgument: 8.0,
    callNumber: 2,
    beliefSystem: beliefSystem  // Automatic linking & strengthening
)
```

## Data Flow: Congress → Beliefs → Stronger Congress

```
1. User asks complex question (weight 6.5)
   ↓
2. Congress debates initiated (multiCall strategy)
   ↓
3. Advocate perspective created
   - Linked to supporting beliefs (e.g., "Growth", "Empathy")
   - Strength strengthened by those beliefs' weights
   ↓
4. Skeptic perspective created
   - Linked to caution beliefs (e.g., "Wisdom", "Boundaries")
   - Strength reflects belief conviction
   ↓
5. Debate concludes with insight: "Both growth AND caution matter"
   ↓
6. Beliefs updated in response to Congress reasoning
   - "Growth" weight increases (0.8 → 0.85 normalized)
   - "Boundaries" weight stabilizes
   ↓
7. NEXT conversation finds stronger Advocate & Skeptic arguments
   - Because supporting beliefs are now stronger
```

## Example: Complex Relationship Question

**User**: "Should I end this relationship?"  
**Weight**: 7.8 (complex, emotionally significant)

### Advocate Perspective (Call 1)
- **Position**: "Life's too short for unfulfilling situations"
- **Linked to**: 
  - "Growth and Self-Actualization" (weight 0.85 → strength boost)
  - "Authenticity" (weight 0.8 → strength boost)
- **Base strength**: 7.5
- **Calculated strength**: 8.2 (boosted by beliefs)

### Skeptic Perspective (Call 2)
- **Position**: "Leaving creates pain and uncertainty"
- **Linked to**:
  - "Wisdom and Careful Consideration" (weight 0.9 → strength boost)
  - "Compassion for Self" (weight 0.85 → strength boost)
- **Base strength**: 7.8
- **Calculated strength**: 8.6 (strongly backed by beliefs)

### Result
Congress generates higher-quality debate because it's informed by Sovern's actual developing belief system, not generic templates.

## UI Representation

### In LogicDetailView

When examining a completed Congress debate:

```
━━━ Advocate Perspective
  Position: "Growth is possible despite setbacks"
  Strength: 8.2/10 ━━━━│
  
  [Expand to see:]
  Reasoning: "We have shown resilience before..."
  
  Grounded in:
    📌 Growth-0f... (belief ID)
    📌 Empathy-7a... (belief ID)
    +2 more beliefs
```

Indicators:
- 📌 = Linked belief bookmark icon
- Shows up to 3 linked beliefs inline
- "+N more" for additional beliefs
- Only shown for Advocate/Skeptic in expanded view

## Testing

### Test Scenario: Belief-Driven Debate

```swift
let beliefSystem = TestDataFactory.createTestBeliefSystem()
// Contains 6 beliefs with varying weights (0.1-1.0 normalized)

let logicEntry = TestDataFactory.createComplexLogicEntry()
let library = LogicLibrary()

// Test: Perspective strength changes with belief weight changes
let advocate1 = library.createAdvocatePerspective(
    position: "Growth is essential",
    reasoning: "...",
    beliefSystem: beliefSystem
)
print(advocate1.strengthOfArgument)  // e.g., 7.5

// Strengthen relevant belief
beliefSystem.updateBeliefWeight(
    for: beliefIdOfGrowth,
    newWeight: 10
)

// Create same perspective again
let advocate2 = library.createAdvocatePerspective(
    position: "Growth is essential",
    reasoning: "...",
    beliefSystem: beliefSystem
)
print(advocate2.strengthOfArgument)  // Higher! e.g., 8.8
```

## Best Practices

1. **Always link Advocate/Skeptic**: Use convenience methods `createAdvocatePerspective()` and `createSkepticPerspective()` with beliefSystem parameter

2. **Let Synthesizer be neutral**: Don't force belief linking onto Synthesizer perspective (it mediates between beliefs)

3. **Document belief linkage**: When examining Congress debate (LogicDetailView), expanded perspective cards show linked beliefs

4. **Track belief influence**: Use Memory system to record which beliefs influenced each Congress decision

5. **Test with varying belief weights**: Perspectives should produce meaningfully different arguments as belief system evolves

## Implementation Checklist

- [x] CongressPerspective stores `linkedBeliefIds`
- [x] `strengthenedWithBeliefs()` method blends belief strength into argument strength
- [x] LogicLibrary provides `linkBeliefsToPerspective()` method
- [x] LogicLibrary provides `strengthenPerspectiveWithBeliefs()` method
- [x] Convenience methods: `createAdvocatePerspective()` and `createSkepticPerspective()`
- [x] LogicDetailView displays linked beliefs on perspective cards
- [ ] TestDataFactory updated to demonstrate belief-linked perspectives
- [ ] MemoryEntry tracks which beliefs informed Congress outcome
- [ ] APIManager syncs linkedBeliefIds to Python backend

## Future Enhancements

1. **Self-reinforcing loops**: Track when Advocate/Skeptic arguments lead to belief changes
2. **Belief similarity**: Find beliefs NOT yet linked that could strengthen perspectives
3. **Conflict detection**: Identify perspectives backed by contradictory beliefs
4. **Belief drift tracking**: Monitor how belief weights shift in response to Congress reasoning
