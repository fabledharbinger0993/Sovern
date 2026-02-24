# Sovern

**A cooperative, self-referencing cognitive agent built on iOS with a local reasoning backend.**

## What is Sovern?

Sovern is a collaborative AI system that learns through a recursive cognitive loop:

1. **Human asks question** → Chat interface captures input
2. **Internal Congress debates** → Four perspectives (Advocate, Skeptic, Synthesizer, Ethics) deliberately reason through complexity
3. **Self-inspection occurs** → Sovern analyzes its own reasoning patterns
4. **Beliefs evolve** → Weights update based on what Sovern learned about itself
5. **Memory accumulates** → Next conversation uses refined self-model
6. **Loop repeats** → Cognitive development, not just retrieval

## Quick Start

### Prerequisites

1. **Ollama** - [Download here](https://ollama.ai)
   ```bash
   ollama pull llama3.2:1b
   ```

2. **USB Thumb Drive** - Labeled `SOVERN` (for data persistence)

3. **Node.js** - v18 or later

### Start Backend Server

```bash
cd server
npm install
npm run dev
```

Server will start on `http://localhost:3001`

## Learn More

- **Backend Developer Guide**: See [server/README.md](./server/README.md)
- **System Architecture**: See [.github/copilot-instructions.md](./.github/copilot-instructions.md)
- **Research Context**: See `MASTER_MEMORY_SYNTHESIS.md` (v3.1)

## Key Components

**Backend** (Node.js + TypeScript):
- Paradigm Agent: Route queries & maintain self-model
- Congress Agent: Multi-perspective deliberation via Ollama
- Ego Agent: Integrate reasoning, mediate belief-expression
- Storage: SQLite on thumb drive

**Frontend** (iOS + SwiftUI):
- Chat interface with real-time responses
- Logic tab: View reasoning traces
- Memory tab: Track learning hints
- Beliefs tab: Hexagon network visualization
- Settings: Dark/light mode, configuration

**Storage**:
- Automatic thumb drive detection (`/mnt/SOVERN`, `/Volumes/SOVERN`, `X:\SOVERN`)
- Fallback to local `./data/sovern.db`

## Architecture Overview

```
Chat Input
    ↓
Paradigm Evaluation (complexity + routing)
    ↓
Congress Deliberation (if complex)
    ├─ Advocate
    ├─ Skeptic
    ├─ Synthesizer
    └─ Ethics
    ↓
Ego Integration (response + mediation)
    ↓
Response + Logic Entry + Memory
    ↓
SQLite Storage (Thumb Drive)
```

## Development

```bash
# Backend
cd server
npm install
npm run dev      # Development
npm start        # Production
npm test         # Tests

# iOS App
# Open in Xcode and build normally
```

## Running on Replit

Click "Run" - `.replit` configuration automatically:
- Installs dependencies
- Builds TypeScript
- Starts backend on port 3001
- Connects to local Ollama

## Marshall's Research

Sovern implements collaborative AI research findings:

- **Relational conditions shape emergence** - How we engage influences what AI becomes
- **Memory continuity essential** - Temporal context enables coherent development
- **Multi-perspective deliberation** - Congress generates novel frameworks
- **Self-examination drives growth** - Analyzing own reasoning patterns

See complete research documentation in `MASTER_MEMORY_SYNTHESIS.md`.

## Key Files

**Backend**: `server/src/{config,types,ollama,storage,reasoning,index}.ts`
**Frontend**: `{ChatView,BeliefsNetworkView,LogicDetailView,MemoryViewTab,ThemeManager}.swift`
**Docs**: `.github/copilot-instructions.md`, `PROJECT_STATUS.md`, `API_VALIDATION_GUIDE.md`

---

**Status**: Active research program
**Last Updated**: February 23, 2026
**Backend**: Node.js + TypeScript + Ollama (local)
**Frontend**: iOS + SwiftUI
**Storage**: SQLite on thumb drive
