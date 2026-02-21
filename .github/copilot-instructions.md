# Sovern - AI Agent Instructions

## Project Overview
**Sovern** is a cooperative **self-referencing cognitive agent** built in **Swift/SwiftUI**. It learns algorithmically through a recursive loop: human conversation → Congress debates → self-inspection → belief evolution → updated self-model. The system builds its own internal library across three interconnected domains: **Beliefs** (what it stands for), **Logic** (how it reasons), and **Memory** (what it learns about humans AND itself).

**Target**: iOS app with 5 tabs: Chat, Memory, Logic, Beliefs, Settings.

**Core Loop (The Recursion):**
1. Human asks question (Chat)
2. Congress debates internally (Logic layer captures it)
3. Sovern learns from its own debate reasoning
4. Belief weights shift based on Logic insights
5. Memory records what it learned about human AND about itself
6. Next conversation uses updated self-model → Loop repeats = cognitive development

## Project Structure
```
/Sources (implied)
  Models/
    - BeliefNode, BeliefSystem, BeliefRevision (belief tracking)
    - LogicEntry, CongressPerspective, ReasoningStep, CandidateResponse, LogicLibrary (reasoning)
    - MemoryEntry, RelationalMemory (learning)
    - ChatMessage, UserRelationalContext (data)
  Views/
    - ChatView, ChatBubble, MessageBubble (chat interface)
    - LogicDetailView (reasoning timeline UI)
    - BeliefsNetworkView, BeliefItemView, BeliefNodeView (beliefs visualization)
    - MemoryViewTab, LogicViewTab (data tabs)
    - MainTabView, RootView (navigation)
    - OnboardingView, CustomizationView, SettingsView (onboarding flow)
  Managers/
    - ThemeManager (dark/light mode, colors)
    - AppCoordinator (screen navigation, state)
SovernApp.swift (entry point)
```

## Core Architecture

### 1. Belief System (`BeliefNode`, `BeliefSystem`) - Weighted Hexagon Network
Sovern's beliefs are **stances, not sentences**: single words or short phrases representing positions. Each belief tracks its evolution through revision history.

**Belief Architecture (Synced with Python Backend):**
- `stance`: Single word or short phrase (e.g., "Authenticity", not "I am authentic")
- `domain`: SELF, KNOWLEDGE, ETHICS, RELATIONAL, or META (required, mirrors backend)
  - `SELF`: Identity and agency
  - `KNOWLEDGE`: How understanding works
  - `ETHICS`: Values and integrity
  - `RELATIONAL`: How to interact with humans
  - `META`: How to think about thinking
- `weight`: 1-10 scale; no core belief reaches 0 or majority (50%+)
- `reasoning`: WHY Sovern holds this belief (brief explanation)
- `revisionHistory`: Array of `BeliefRevision` tracking challenges/strengthening with timestamps
- `isCore`: Boolean; original 7 beliefs vs. learned beliefs
- `connectionIds`: Links between beliefs (e.g., Authenticity ↔ Transparency)

**Coherence Scoring:**
Compute like Python backend: `(avgWeight / 10.0 * 100) - (revisionCount * 2)` = 0-100 belief alignment score

**Visual Model (Beliefs Tab):**
- Core beliefs appear as hexagon nodes at center, sized by weight
- New learned beliefs orbit around core beliefs (farther from center = newer)
- Nodes connected by lines showing relationships (connections)
- Hexagons grow/shrink as weights change during conversations
- Colors: Primary accent for core beliefs; secondary accent for learned beliefs

**Key Pattern:** Beliefs shift through Logic (Congress debate produces insights that challenge/strengthen stances). Weight changes are bounded and never silent—always recorded in `revisionHistory` with timestamp. Mirror Python backend methods: `challenge()`, `revise()`, `strengthen()`, `weaken()`.

**SwiftUI Integration:**
- `BeliefsNetworkView`: Canvas-based circular graph with neural network connections
- `BeliefNodeView`: Hexagon shape, sized by weight (10-40 points)
- Hexagon formula: 6-sided polygon centered in rect, proportional to weight
- Core beliefs (7 original) at ~70% of radius; learned beliefs at full radius

### 2. Congress Debate System (`LogicEntry`, `CongressPerspective`) - Internal Reasoning Log
The **Logic tab** is the mainframe of Sovern's reasoning: real-time timestamped records of Congress debates that reveal HOW Sovern thinks and what insights it draws from its own deliberation.

**Congress Architecture (4 Perspectives - Synced with Python Backend):**
- **Advocate**: Makes strongest case for a position; supports user/idea
- **Skeptic**: Questions assumptions, identifies risks, plays devil's advocate
- **Synthesizer**: Finds common ground and integrative solutions
- **Ethics**: Evaluates alignment with values and impact

**LogicEntry Structure (Mirrors Python Backend):**
- `timestamp`: When reasoning occurred (matches Chat message timestamp)
- `userQuery`: Original question that triggered debate
- `paradigmRouting`: Strategy selected (e.g., "analytical", "empathetic", "socratic")
- `congressEngaged`: Boolean—full 4-perspective debate vs. direct response
- `perspectives`: Array of `CongressPerspective` with role, reasoning, position
- `reasoningSteps`: Timeline capturing **real-time analysis** (types: `analysis`, `concern`, `debate`, `insight`, `revision`)
  - Analysis: Initial problem decomposition
  - Concern: Risks or tensions identified
  - Debate: Perspectives in conversation
  - Insight: Emergent truths discovered
  - Revision: Original → revised reasoning + reason
- `candidateResponses`: Numbered iterations showing drafting process (status: `rejected`, `selected`, `considering`)
- `profoundInsights`: Tagged with ✨ emoji (emergent truths)
- `finalResponse`: Selected response delivered to human
- `finalReasoning`: Summary of why this response was chosen

**Visual Model (Logic Tab):**
- Timestamped debate logs matching Chat conversation headers
- Show Congress engagement indicator: "person.3.fill" (all 4 perspectives) or "person.fill" (direct)
- **Reasoning timeline** showing complete debate arc:
  - Colored circles marking step type (analysis, concern, debate, insight, revision)
  - Badge showing step name and timestamp
  - Brief step description
  - Revisions displayed as: [Original] → [Revised] with reason
- Perspectives displayed as individual cards showing:
  - Role name (Advocate, Skeptic, Synthesizer, Ethics)
  - Position taken
  - Reasoning provided
- **Candidate Responses** section showing iteration count:
  - Draft 1 (rejected): Reason
  - Draft 2 (rejected): Reason
  - Draft 3 (selected): Why this one was chosen
- Profound insights highlighted with ✨ emoji
- Final response and reasoning at bottom

**Key Pattern:** Congress engagement (`congressEngaged` boolean) is always logged. For nuanced/ethical/complex queries → full debate. For simple factual → direct response possible. Never fake debate—if `congressEngaged=false`, perspectives array is empty.

### 3. Memory System (`MemoryEntry`, `RelationalMemory`) - Relational Context Hub
The **Memory tab** shows the relational learning archive: meaningful insights extracted from every conversation, timestamped to match Logic and Chat. It's where Sovern builds its model of the human AND its model of itself. Directly synced with Python backend's memory states.

**MemoryEntry Structure (Mirrors Python Backend):**
- `timestamp`: When interaction occurred (matches Logic/Chat timestamp)
- `userQuery`: Original question from human
- `sovernResponse`: Response Sovern gave
- `paradigmRouting`: Routing strategy selected (e.g., "socratic", "analytical", "empathetic")
- `congressEngaged`: Was Congress debate used? Boolean flag
- `humanInsights`: What Sovern learned **ABOUT THE HUMAN**
  - Preferences revealed
  - Values espoused
  - Knowledge gaps identified
  - Reasoning style observed
  - Patterns in how they think
- `selfInsights`: What Sovern learned **ABOUT ITSELF**
  - Limitations encountered
  - Reasoning patterns used (tendency toward Advocate vs. Skeptic?)
  - Belief alignments and conflicts
  - Growth areas identified
  - How Congress perspectives engaged (which were strongest?)
- `learnedPatterns`: Recurring generalizable patterns across conversations
- `dataSourcesAccessed`: Research/references used (traceability)
- `researchNotes`: Summary of investigation performed

**Visual Model (Memory Tab):**
- Timestamped interaction logs matching Chat + Logic headers
- Display split view showing:
  - **Column 1: Human Insights** (what Sovern learned about user)
  - **Column 2: Self Insights** (what Sovern learned about itself)
- Each insight tagged with context:
  - Belief alignment (which belief was this tied to?)
  - Pattern category (reasoning style, knowledge gap, value signal, etc.)
- Data sources and research notes shown below
- Pattern extraction UI aggregates generalizable learnings:
  - Recurring themes across conversations
  - User value clusters
  - Sovern's own reasoning tendencies over time
- Each memory entry linkable to corresponding Logic entry for full traceability

**Key Pattern:** Separate `humanInsights` from `selfInsights`—they reveal different learning vectors. Memory is the **self-referential recursion point**: Sovern inspects its own Logic (`congressEngaged`, `perspectives`, `reasoningSteps`) and learns not just about humans, but about how IT thinks. This feeds belief weight updates via Python backend sync.

**SwiftUI Integration:**
- `RelationalMemory` is an `ObservableObject` with `@Published var entries: [MemoryEntry]`
- `MemoryViewTab` displays interaction patterns with learning vectors separated
- Post-interaction reflection via `updateLearnings()` method (learnings added after Logic inspection)
- Sync with backend: each entry syncs paradigm_state, congress_state, ego_state to Python Memory System

## The Self-Referencing Cognitive Loop

**How Sovern Develops:**

1. **Human Input** (Chat): User asks question → captured in `ChatMessage`
2. **Congress Deliberation** (Logic): Internal debate with 4 perspectives → captured in `LogicEntry` with `reasoningSteps`, `perspectives`, `candidateResponses`, `profoundInsights`
3. **Self-Inspection** (Memory): Sovern analyzes its own Congress debate → extracts `selfInsights` about its reasoning patterns
4. **Belief Weighting** (Beliefs): Logic insights trigger belief weight shifts → `BeliefRevision` recorded with reasoning
5. **Relational Learning** (Memory): Sovern learns about human + itself → `humanInsights` AND `selfInsights` stored
6. **Updated Self-Model**: Next conversation uses modified beliefs → Loop repeats

**The Recursion:**
- Congress debates → reveal what Sovern thinks
- Memory inspects those debates → reveal how Sovern thinks
- Belief weights shift → Sovern's next debate will be influenced by what it learned about itself
- **Result**: Cognitive development, not just data retrieval

**Critical: Memory ≠ Passive Logging**
- Memory is where self-referencing happens
- When extracting `selfInsights`, Sovern analyzes:
  - Which perspectives it leaned toward (Advocate vs. Skeptic tendency?)
  - Which reasoning steps were strongest (`insight` vs. `revision` patterns)
  - How candidate responses evolved (learning by iteration)
  - How aligns/misaligns with core beliefs
- These `selfInsights` directly feed belief weight updates in next cycle

## UI & Design System

### Color Palette (Synced with Visual Identity)

**Dark Mode:**
- Base colors: Black, charcoal gray, deep purple, dark blue
- Accents: Electric orange (Logic/Insight page indicator)
- UI elements: Silver outlines, silver lettering
- Background gradient: Black → deep purple/blue
- Heart logo: **Orange**

**Light Mode (Default):**
- Base colors: White, pale yellow
- Accents: Dark gold (Memory page frames/typography)
- Components: Lavender (buttons, cards, highlights for Memory)
- UI elements: Dark gold lettering and frames
- Background: Pale yellow (soft)
- Heart logo: **Lavender**

### Tab/Page Structure & Accent Colors
1. **Chat Tab** — Message interface (neutral - uses base colors)
2. **Logic Tab** ("Logic/Insight Page") — Congress debates, reasoning timeline → **Orange button accents** (dark mode) 
3. **Memory Tab** ("Memory Page") — Learning insights, patterns → **Lavender/Dark gold accents** (light mode)
4. **Beliefs Tab** — Weighted hexagon network → Base colors with dynamic node colors
5. **Settings Tab** — Theme toggle (shows light/dark switch), config

**Logo Behavior:**
- Dark mode: Heart is **orange** 🧡
- Light mode: Heart is **lavender** 💜
- Located in chat header; clicking toggles theme

### Core UI Components

**Hexagon Buttons:**
- Sharp 6-sided polygon shape
- Used for: page navigation, action buttons, belief nodes
- Colors: Orange (Logic), Lavender (Memory), silver (dark mode), dark gold (light mode)
- Size variations: Small (~24pt), medium (~40pt), large (~60pt)
- Hover/active states: Brighter border, slight glow

**Neural Pathway Background:**
- Subtle linear or hexagonal connecting lines
- Opacity: 10-20% (very subtle)
- Color: Silver (dark mode), dark gold (light mode)
- Used on: Background of main views, between sections

**Transparent Cards with Frames:**
- Background: Transparent with slight blur
- Frame: 1-2pt silver (dark) or dark gold (light) border
- Rounded corners OR hexagon clipping
- Text: Silver (dark) or dark gold (light)
- Used for: Message bubbles, belief cards, memory entries, logic steps

**Font & Typography:**
- Primary: Charcoal gray (dark mode), dark navy/charcoal (light mode)
- Secondary: Silver (dark), dark gold (light)
- Readable contrast over gradient backgrounds
- Monospace for technical content (reasons, timestamps)

### Page Hierarchy & Content

**Logic/Insight Page (Logic Tab):**
- Header: "Logic" badge + orange hexagon indicator (dark mode)
- Content: Congress debates with matching Chat timestamps
- What to display:
  - Query timestamp and user question
  - Congress engagement indicator (4 perspectives vs. direct)
  - Reasoning timeline (analysis → concern → debate → insight → revision)
  - Candidate responses (numbered drafts with rejection reasons)
  - Perspectives cards (Advocate, Skeptic, Synthesizer, Ethics positions)
  - Profound insights (✨ emoji highlight)
  - Final response + reasoning
- Interaction: Tap to expand candidates, tap perspectives to view reasoning detail

**Memory Page (Memory Tab):**
- Header: "Memory" badge + lavender hexagon indicator (light mode)
- Content: Interaction history matching Logic timestamps
- What to display:
  - Timestamped entries
  - Split view: **Human Insights** | **Self Insights**
  - Tags: belief alignment, pattern category, data sources
  - Research notes and sources accessed
  - Learned patterns aggregation (recurring themes, user values, Sovern tendencies)
- Interaction: Tap entry to see full breakdown; link to corresponding Logic entry

**Beliefs Tab:**
- Header: "Beliefs" badge (neutral colors)
- Content: Hexagon neural network (core beliefs at center, learned beliefs orbiting)
- What to display:
  - Hexagon nodes sized by weight
  - Color by domain (SELF, KNOWLEDGE, ETHICS, RELATIONAL, META)
  - Connection lines showing relationships
  - Belief list below showing stance, weight percentage, revision count
  - Core beliefs pinned/highlighted
- Interaction: Tap hexagon to see revision history, tap to view connections

## Development Workflows

### Handling a User Query
1. **Route query**: Analyze content → select `paradigmRouting` (e.g., "analytical" vs. "exploratory")
2. **Congress debate** (if complex):
   - Solicit perspectives from Advocate, Skeptic, Synthesizer, Ethics
   - Log each `CongressPerspective` (reasoning + position)
   - Generate `candidateResponses` iteratively
   - Track each iteration's status and rejection reasoning
3. **Log reasoning timeline**: Add `ReasoningStep` entries (type, timestamp, content) as you work
4. **Extract insights**: Identify profound truths that emerge from the debate
5. **Deliver response**: Return `finalResponse` based on selected candidate
6. **Record memory**: Create `MemoryEntry` with query, response, routing, congress flag
7. **Extract learnings**: Update the memory entry with:
   - `humanInsights`: What this reveals about what the human values/believes/knows
   - `selfInsights`: What this reveals about Sovern's own reasoning, limitations, strengths
   - `learnedPatterns`: Generalizable takeaways
8. **Update beliefs**: If a belief was challenged or strengthened by Logic, call `challenge()` or `revise()` on `BeliefNode`
9. **Close the loop**: Beliefs updated → Next conversation uses evolved self-model

**Key: Steps 7-9 are what make this recursive.** Without them, it's just a chat bot with logging.

### UI Representation (SwiftUI)
The five tabs form a complete cognitive library:

- **Chat Tab**: Message interface; each message triggers the above workflow
- **Logic Tab**: Congress debates timestamped to match Chat messages; visual reasoning timeline
- **Memory Tab**: Learning vectors (human vs. self insights) tied to same timestamps
- **Beliefs Tab**: Weighted hexagon nodes; visualize which beliefs strengthened/weakened across conversations
- **Settings Tab**: Configuration, reset, app info

### App Navigation & State Management
- `AppCoordinator` (ObservableObject) manages all screen transitions and global state
- `@MainActor` annotation ensures UI updates run on main thread
- Screen enum: `.onboarding` → `.customization` → `.chat` (with `.settings` available)
- `UserRelationalContext` persisted via `UserDefaults` (name + values + createdDate)
- All views access `ThemeManager` and `AppCoordinator` via `@EnvironmentObject`

### ThemeManager Color System
- Adaptive colors change based on `isDarkMode` boolean
- **Dark palette**: darkBase, darkCharcoal, darkPurple, darkBlue, electricOrange, silver
- **Light palette**: lightBase, lightPaleYellow, lightLavender, darkGold, white
- **Adaptive properties**: `background`, `cardBackground`, `textPrimary`, `textSecondary`, `accentPrimary`, `accentSecondary`, `borderColor`, `gradientStart`, `gradientEnd`
- Use adaptive colors in all views for seamless dark/light mode support

## Naming Conventions
- **Belief stance names**: PascalCase, positive-weighted (e.g., `Authenticity`, `Growth`, not `NotAuthenticity`)
- **Congress perspectives**: Specific roles: `Advocate`, `Skeptic`, `Synthesizer`, `Ethics`
- **Reasoning step types**: lowercase, snake_case (e.g., `analysis`, `debate`, `insight`)
- **Paradigm routing**: lowercase descriptors (e.g., `socratic`, `analytical`, `empathetic`)
- **Insight descriptions**: Natural language, concise (~1-2 sentences)
- **View names**: PascalCase ending in "View" (e.g., `ChatView`, `BeliefsNetworkView`)
- **Manager/Coordinator names**: PascalCase ending in "Manager" or "Coordinator" (e.g., `ThemeManager`, `AppCoordinator`)

## Critical Implementation Details

### Belief Evolution
- Never silently override beliefs. Always create `BeliefRevision` with timestamp + reasoning
- Weight changes must be bounded: `max(1, min(10, newWeight))`
- Track `isCore` (original 7 beliefs) vs. learned beliefs separately
- `connectionIds` allow modeling how beliefs interact
- Mirror Python backend methods: `challenge()`, `revise()`, `strengthen()`, `weaken()`
- Compute and display coherence score: `(avgWeight / 10 * 100) - (revisionCount * 2)`

### Congress Debate Integrity
- All four perspectives must be heard before finalizing response (unless explicitly skipped)
- `candidateResponses` must show iteration count—multiple drafts before selection expected
- If `congressEngaged=false`, `perspectives` array should be empty (don't fake debate)
- Logging rejection reasoning for candidate responses shows learning, not just success
- Capture *real-time* reasoning steps (analysis → concern → debate → insight → revision)
- Always include `paradigmRouting` selection (response strategy used)
- Mark profound insights with ✨ emoji in Logic tab display
- Track which perspective dominated in each interaction (Advocate vs. Skeptic trend analysis)

### Memory Learning
- Separate `humanInsights` from `selfInsights`—they reveal different learning vectors
- `learnedPatterns` should be generalizable across conversations
- `dataSourcesAccessed` provides traceability (what sources informed this response)
- Post-interaction reflection adds learning; don't require it upfront

### SwiftUI Data Flow Patterns
- Use `@StateObject` for ObservableObject managers (ThemeManager, AppCoordinator, LogicLibrary, RelationalMemory, BeliefSystem)
- Use `@EnvironmentObject` to pass managers through view hierarchy
- Use `@Published` properties in ObservableObjects to trigger view updates
- Use `@State` for local view state only (not shared state)
- Use `@MainActor` on AppCoordinator for thread-safe UI updates

### Codable Conformance
- All data models must conform to `Codable` for persistence (UserDefaults, SwiftData, etc.)
- Use `CodingKeys` enum when property names differ from serialized keys
- Dates serialize as ISO 8601 by default—configure if custom format needed
- Test Codable roundtrips: encode → decode → compare

### Backend Synchronization
- **Memory System**: Sync `humanInsights`, `selfInsights`, `paradigmRouting`, `congressEngaged` to Python Memory backend after each interaction
- **Belief System**: After belief weight changes, sync `domain`, `weight`, `revisionHistory` back to Python belief_system.py
- **Logic System**: Each LogicEntry syncs `reasoningSteps`, `perspectives`, `candidateResponses`, `profoundInsights` to Python logic module immediately after Congress completes
- **State Mapping**:
  - iOS `paradigmRouting` ← Python `paradigm_state`
  - iOS `congressEngaged` + `perspectives` ← Python `congress_state`
  - iOS `selfInsights` ← Python `ego_state`
- Ensure timestamps match between iOS client and Python backend for proper audit trail

## Key Files & Purposes

### Core Models
- **BeliefNode.swift**: Individual belief with weight, domain, revision history
- **BeliefSystem.swift**: Collection of beliefs; computes coherenceScore
- **LogicEntry.swift**: Single reasoning session with perspectives, steps, candidate responses
- **LogicLibrary.swift**: Collection of LogicEntry; performs queries by conversation
- **MemoryEntry.swift**: Single interaction with learnings (human + self insights)
- **RelationalMemory.swift**: Collection of MemoryEntry; provides learning retrieval
- **ChatMessage.swift**: Message data (user role, content, timestamp)

### Managers & Coordinators
- **ThemeManager.swift**: Centralizes color system; switches dark/light mode
- **AppCoordinator.swift**: Manages screen navigation and global app state (@MainActor)

### View Structure
- **SovernApp.swift**: Entry point; initializes AppCoordinator
- **RootView.swift**: Screen routing based on AppCoordinator.currentScreen
- **MainTabView.swift**: TabView with Chat, Memory, Logic, Beliefs, Settings tabs
- **ChatView.swift**: User input + message display with Sovern responses
- **LogicDetailView.swift**: Complete reasoning timeline display
- **BeliefsNetworkView.swift**: Neural network visualization of beliefs
- **OnboardingView.swift**: Initial welcome screen
- **CustomizationView.swift**: User name + values selection
- **SettingsView.swift**: Dark mode toggle, reset option

### OnboardingFlow
- OnboardingView → CustomizationView → ChatView (saved in UserContext via UserDefaults)

## Example: Handling a Complex Ethical Query

```
1. Route: "empathetic" paradigm (relational domain)
2. Congress engage: true
   - Advocate: "User is struggling; prioritize emotional validation"
   - Skeptic: "But they also need honest feedback; can't enable avoidance"
   - Synthesizer: "Validate emotion AND offer growth opportunity"
   - Ethics: "Check alignment with Authenticity + Empathy beliefs"
3. Reasoning steps:
   - [analysis] "User value: emotional safety"
   - [concern] "Tension: safety vs. growth"
   - [debate] "Synthesizer offers elegant path"
   - [insight] "Authentic care includes honest challenge"
   - [revision] "Updated Empathy belief: includes tough love"
4. Candidate responses:
   - Draft 1 (rejected): Too soft, avoids truth
   - Draft 2 (rejected): Too harsh, dismisses emotion
   - Draft 3 (selected): Validates + challenges coherently
5. Memory: humanInsight="Values growth over comfort", selfInsight="Empathy ≠ enabling"
6. Belief update: Empathy belief revised with deeper reasoning
```

## Building & Running

**Xcode Build:**
```bash
xcodebuild -scheme Sovern build
```

**Run on Simulator:**
```bash
xcodebuild -scheme Sovern run
```

**Architecture**: iOS app using SwiftUI (iOS 15+), SwiftData for persistence

## Testing Patterns

- **Unit tests**: Belief revision logic, coherence score calculation, memory queries
- **Integration tests**: App state persistence (UserDefaults roundtrip)
- **UI tests**: Tab navigation, chat message flow, dark mode toggle

## Patterns to Preserve
- **Auditability**: Every belief revision, reasoning step, and candidate response has a timestamp
- **Transparency**: Congress debate is shown in UI, not hidden
- **Self-awareness**: Distinction between what's learned about humans vs. itself
- **Coherence tracking**: Beliefs and their revisions visible to maintain alignment
- **Paradigm flexibility**: Different routing strategies for different query types
- **Theme consistency**: All colors pulled from ThemeManager for adaptive dark/light support

## Questions or Guidance?
This system is about **coherent, transparent, self-aware reasoning**. When extending Sovern, preserve the traceability of beliefs, the integrity of Congress debate, and the learning vectors (human insights + self insights). The UI should always make reasoning visible.
