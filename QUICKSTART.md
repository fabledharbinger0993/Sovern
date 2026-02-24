# Sovern Backend - Quick Start Guide

## 📋 Prerequisites

Before starting, make sure you have:

- **Ollama** installed from [ollama.ai](https://ollama.ai)
- **Llama 3.2:1b pulled**: `ollama pull llama3.2:1b`
- **Node.js 18+** installed
- **USB Thumb Drive** labeled `SOVERN` (optional but recommended for persistence)

## 🚀 Launch Steps

### Step 1: Start Ollama Server (New Terminal Window)

```bash
ollama serve
```

Leave this running. You should see:
```
Listening on 127.0.0.1:11434 (HTTP)
```

### Step 2: Start Backend Server

```bash
cd /workspaces/Sovern
cd server
npm install             # First time only
npm run dev             # Watch mode
```

You should see:
```
╔════════════════════════════════════════════════════════════╗
║           SOVERN BACKEND - Ready to Reason                ║
╚════════════════════════════════════════════════════════════╝

📍 Server: http://localhost:3001
🧠 Ollama: http://localhost:11434
📦 Model: llama3.2:1b
💾 Storage: /path/to/SOVERN/sovern.db
```

### Step 3: Verify It Works

Test the health endpoint:
```bash
curl http://localhost:3001/health
```

Should return:
```json
{
  "status": "ok",
  "ollama": "connected",
  "database": "/path/to/SOVERN/sovern.db",
  "stats": {...}
}
```

### Step 4: Send Your First Message

```bash
curl -X POST http://localhost:3001/api/chat/messages \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "test-1",
    "message": "What does authenticity mean to you?",
    "userId": "user-1"
  }'
```

Watch the Ollama terminal - you'll see the model running Congress deliberation.

## 🔗 Connect iOS App

1. Get your computer's local IP:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # Windows (in PowerShell)
   ipconfig
   ```

2. In iOS app, go to Settings
3. Set API Endpoint to `http://YOUR_IP:3001`
4. Start chatting!

## 📂 Data Location

Data automatically saves to thumb drive:
- **Linux**: `/mnt/SOVERN/sovern.db`
- **macOS**: `/Volumes/SOVERN/sovern.db`
- **Windows**: `X:\SOVERN\sovern.db`

If you eject the drive or restart, it persists. Remove the drive and it falls back to `./data/sovern.db` locally.

## 🛠️ Development Commands

```bash
cd server

npm run dev       # Watch mode (for development)
npm run build    # Compile TypeScript
npm start        # Run compiled production
npm test         # Run tests (when ready)
```

## ⚡ Troubleshooting

### "Ollama not connected"
- Make sure `ollama serve` is running in another terminal
- Check it's accessible: `curl http://localhost:11434/api/tags`

### "Model not found"
```bash
ollama pull llama3.2:1b
```

### "Port 3001 already in use"
```bash
PORT=3002 npm run dev     # Use different port
```

### "Thumb drive not detected"
- Works fine! Falls back to local storage
- Insert drive labeled `SOVERN` to use it

### "No response from API"
- Check if backend is running: `curl http://localhost:3001/health`
- Check Ollama is running: `curl http://localhost:11434/api/tags`
- Check console for errors

## 📊 API Examples

### Send message and get full reasoning
```bash
curl -X POST http://localhost:3001/api/chat/messages \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "conv-1",
    "message": "Should I tell the truth even if it hurts?"
  }' | jq
```

### View all beliefs
```bash
curl http://localhost:3001/api/beliefs | jq
```

### Check tensions (unresolved conflicts)
```bash
curl http://localhost:3001/api/tensions | jq
```

### Get self-review (analyze reasoning patterns)
```bash
curl -X POST http://localhost:3001/api/self-review | jq
```

### View recent reasoning (logic entries)
```bash
curl "http://localhost:3001/api/logic?limit=5" | jq
```

### View learning history (memory)
```bash
curl "http://localhost:3001/api/memory?limit=5" | jq
```

## 🎭 What's Happening

When you send a message, here's the flow:

1. **Paradigm** evaluates complexity (1-9 scale)
2. If complex enough (3+), **Congress** debates:
   - Advocate positions possibilities
   - Skeptic challenges assumptions
   - Synthesizer finds integration
   - Ethics checks values
3. **Ego** selects best response and checks if it aligns with beliefs
4. Response + reasoning traces + learning insights stored to database
5. Thumb drive is updated

See `server/README.md` for complete API reference.

## 🚀 Next Steps

1. **Send multiple messages** to watch belief weights evolve
2. **Check `/api/self-review`** to see reasoning patterns
3. **View `/api/tensions`** to see unresolved conflicts emerging
4. **Connect iOS app** to visualize beliefs as hexagon network
5. **Read research** in `MASTER_MEMORY_SYNTHESIS.md` to understand the "why"

## Questions?

See `server/README.md` for complete developer documentation.

Enjoy building with Sovern! 🧠✨
