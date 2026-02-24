# Sovern Backend Server

Complete Paradigm-Congress-Ego cognitive reasoning engine with local Ollama integration.

## Quick Start

### Prerequisites

1. **Ollama** - Download from [ollama.ai](https://ollama.ai)
2. **Llama 3.2:1b Model** - Run: `ollama pull llama3.2:1b`
3. **Node.js 18+** - [nodejs.org](https://nodejs.org)
4. **USB Thumb Drive** - Labeled `SOVERN` for persistent data storage

### Setup

```bash
# 1. Install dependencies
cd server
npm install

# 2. Ensure Ollama is running
ollama serve  # In a separate terminal

# 3. Start the backend
npm run dev   # Development with hot reload
npm start     # Production build
```

### Environment Variables

```bash
# .env (optional - defaults provided)
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2:1b
NODE_ENV=development
PORT=3001
```

## Data Storage

**Automatic**: Sovern detects your thumb drive and stores data at:
- Linux: `/mnt/SOVERN/sovern.db`
- macOS: `/Volumes/SOVERN/sovern.db`
- Windows: `X:\SOVERN\sovern.db`

**Fallback**: If thumb drive not found, data stores locally in `./data/sovern.db`

## API Reference

### Chat

```bash
curl -X POST http://localhost:3001/api/chat/messages \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "conv-1",
    "message": "What does authenticity mean to you?",
    "userId": "user-1"
  }'
```

**Response** (ChatResponse):
```json
{
  "id": "msg-uuid",
  "conversationId": "conv-1",
  "message": "Sovern's response...",
  "timestamp": "2026-02-18T10:30:00Z",
  "logicEntry": { ... },      // Full reasoning trace
  "memoryEntry": { ... }      // Learning extracted
}
```

### Beliefs

**Get all beliefs**:
```bash
curl http://localhost:3001/api/beliefs
```

**Create belief**:
```bash
curl -X POST http://localhost:3001/api/beliefs \
  -H "Content-Type: application/json" \
  -d '{"stance": "Authenticity", "domain": "SELF", "isCore": true}'
```

**Update belief weight**:
```bash
curl -X PATCH http://localhost:3001/api/beliefs/BELIEF-ID/weight \
  -H "Content-Type: application/json" \
  -d '{"newWeight": 7, "reasoning": "Strengthened through conversation"}'
```

### Logic (Reasoning Traces)

```bash
# Get recent reasoning entries
curl "http://localhost:3001/api/logic?limit=10"

# Get specific entry
curl http://localhost:3001/api/logic/LOGIC-ID
```

### Memory (Learning History)

```bash
# Get recent memory entries
curl "http://localhost:3001/api/memory?limit=10"

# Get specific entry
curl http://localhost:3001/api/memory/MEMORY-ID
```

### Self-Review

```bash
curl -X POST http://localhost:3001/api/self-review
```

**Response**: Analysis of reasoning patterns (Advocate vs Skeptic dominance, revision rates, etc.)

### Tensions (Unresolved Conflicts)

```bash
curl http://localhost:3001/api/tensions
```

### Health Check

```bash
curl http://localhost:3001/health
```

## Architecture

### Three-Agent System

**PARADIGM**: Self-model + relational context evaluator
- Ingests incoming query
- Evaluates complexity (1-9 scale)
- Routes to Congress or direct response
- Maintains belief/memory context

**CONGRESS**: Multi-perspective deliberation
- Advocate: Steelmans possibilities
- Skeptic: Stress-tests assumptions
- Synthesizer: Finds integrative solutions
- Ethics: Checks value alignment

**EGO**: Final integration & mediation
- Selects best candidate response
- Mediates between belief and expression
- Preserves relational integrity
- Logs incongruent patterns (belief vs behavior)

### Data Flow

```
User Message
    ↓
Paradigm Evaluation (route + complexity)
    ↓
Congress Deliberation (if complex enough)
    │
    ├─ Advocate perspective
    ├─ Skeptic perspective
    ├─ Synthesizer perspective
    └─ Ethics review
    ↓
Ego Integration (select response, check congruence)
    ↓
Response + Logic Entry + Memory Entry
    ↓
Storage (SQLite on thumb drive)
```

## Database Schema

**Tables**:
- `belief_nodes` - Core beliefs with weights
- `belief_revisions` - Tracked weight changes
- `logic_entries` - Full reasoning traces
- `memory_entries` - Learning insights
- `chat_messages` - Conversation history
- `incongruent_patterns` - Belief vs expression discrepancies
- `epistemic_tensions` - Unresolved conflicts

## Running on Replit

1. Push code to integrated Replit repository
2. Replit detects `.replit` configuration
3. Click "Run" → Automatically:
   - Installs dependencies
   - Starts Ollama connection check
   - Launches backend on port 3001

## Connecting iOS App

Configure your iOS app to point to backend:

```swift
let apiUrl = "http://YOUR_COMPUTER_IP:3001"  // e.g., 192.168.1.100
```

## Troubleshooting

### Ollama Not Detected

```bash
# Ensure Ollama is running in separate terminal
ollama serve

# Check connection
curl http://localhost:11434/api/tags
```

### Model Not Found

```bash
# Pull the model
ollama pull llama3.2:1b
```

### Thumb Drive Not Found

Works without it—fallback to local `./data/sovern.db`. To use thumb drive:
1. Insert drive labeled `SOVERN`
2. Restart server

### Port Already in Use

```bash
PORT=3002 npm run dev  # Use different port
```

## Development

```bash
# Watch mode
npm run dev

# Build
npm run build

# Run compiled
npm start

# Tests (when ready)
npm test
```

## Performance Tips

- Ollama runs locally (no API latency)
- Llama 3.2:1b is small (~2GB) but capable
- SQLite persisted to thumb drive for durability
- Congress deliberation typically takes 3-8 seconds per query

For faster responses, consider larger model if your machine supports it:
```bash
ollama pull llama2  # Larger, more capable
OLLAMA_MODEL=llama2 npm run dev
```

## License

Part of Sovern - Collaborative AI Research Platform
