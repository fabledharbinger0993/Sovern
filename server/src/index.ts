/**
 * Express server for Sovern backend
 * REST API for chat, beliefs, logic, memory, and reasoning
 */

import express, { Request, Response } from 'express';
import cors from 'cors';
import { CONFIG, DB_PATH } from './config.js';
import { ollama } from './ollama.js';
import { storage } from './storage.js';
import { reasoningEngine } from './reasoning.js';
import { v4 as uuid } from 'uuid';
import type {
  ChatMessage,
  ChatRequest,
  ChatResponse,
  BeliefNetworkResponse,
  ConversationHistory,
  SelfReviewReport,
  MemoryEntry,
  LogicEntry,
  IncongruentPatternLog,
  EpistemicTension,
} from './types.js';

const app = express();

// ============================================================================
// MIDDLEWARE
// ============================================================================

app.use(cors());
app.use(express.json());

// ============================================================================
// HEALTH CHECK
// ============================================================================

app.get('/health', async (req: Request, res: Response) => {
  const ollamaHealth = await ollama.checkHealth();

  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    ollama: ollamaHealth ? 'connected' : 'disconnected',
    database: DB_PATH,
    stats: storage.getStats(),
  });
});

// ============================================================================
// CHAT ENDPOINTS
// ============================================================================

app.post('/api/chat/messages', async (req: Request, res: Response) => {
  try {
    const { conversationId, message, userId } = req.body as ChatRequest;

    if (!conversationId || !message) {
      return res.status(400).json({ error: 'conversationId and message required' });
    }

    // Store user message
    const userMsgId = uuid();
    const userMsg: ChatMessage = {
      id: userMsgId,
      conversationId,
      role: 'user',
      content: message,
      timestamp: new Date(),
    };
    await storage.createChatMessage(userMsg);

    // Get conversation context for belief/memory injection
    const history = await storage.getConversationHistory(conversationId);
    const recentBeliefs = await storage.getAllBeliefs();
    const recentMemories = await storage.getRecentMemoryEntries(5);

    // Build context strings
    const beliefContext = recentBeliefs
      .map(b => `- ${b.stance} (weight: ${b.weight}/10, domain: ${b.domain})`)
      .join('\n') || 'No beliefs yet.';

    const memoryContext = recentMemories
      .slice(0, 3)
      .map(m => {
        const insight = m.humanInsights?.[0]?.content || m.selfInsights?.[0]?.content || 'Memory recorded';
        return `- [${m.timestamp.toLocaleDateString()}] ${insight}`;
      })
      .join('\n') || 'No prior memory.';

    // Process query through Paradigm-Congress-Ego
    const logicEntry = await reasoningEngine.processQuery(
      message,
      beliefContext,
      memoryContext
    );

    // Store logic entry
    const savedLogic = await storage.createLogicEntry(logicEntry);

    // Extract memory from reasoning
    const memoryData: MemoryEntry = {
      id: uuid(),
      timestamp: new Date(),
      userQuery: message,
      sovernResponse: logicEntry.finalResponse,
      paradigmRouting: logicEntry.paradigmRouting,
      congressEngaged: logicEntry.congressEngaged,
      humanInsights: [
        {
          category: 'interaction_pattern',
          content: `User asked: "${message.substring(0, 50)}..."`,
          confidence: 75,
        },
      ],
      selfInsights: [
        {
          category: 'reasoning_pattern',
          content: `Used ${logicEntry.paradigmRouting} routing. Congress: ${logicEntry.congressEngaged}`,
          confidence: 90,
          evidenceFromLogic: savedLogic.id,
        },
      ],
      learnedPatterns: [],
      dataSourcesAccessed: [],
      researchNotes: `Raw query complexity: ${logicEntry.complexityWeight}/9`,
      logicEntryId: savedLogic.id,
    };

    const savedMemory = await storage.createMemoryEntry(memoryData);

    // Store assistant message
    const assistantMsgId = uuid();
    const assistantMsg: ChatMessage = {
      id: assistantMsgId,
      conversationId,
      role: 'assistant',
      content: logicEntry.finalResponse,
      timestamp: new Date(),
      logicEntryId: savedLogic.id,
      memoryEntryId: savedMemory.id,
    };
    await storage.createChatMessage(assistantMsg);

    // Detect and track tensions
    for (const tension of logicEntry.perspectives
      .filter(p => p.strengthOfArgument < 5)
      .map((p, idx) => ({
        description: `Tension in ${logicEntry.paradigmRouting} routing`,
        belief1: 'Authenticity',
        belief2: p.role,
      }))) {
      await storage.createOrUpdateTension(tension as EpistemicTension);
    }

    const response: ChatResponse = {
      id: assistantMsgId,
      conversationId,
      message: logicEntry.finalResponse,
      timestamp: assistantMsg.timestamp,
      logicEntry: savedLogic,
      memoryEntry: savedMemory,
    };

    return res.json(response);
  } catch (err) {
    console.error('Chat error:', err);
    return res.status(500).json({
      error: 'Failed to process message',
      details: err instanceof Error ? err.message : 'Unknown error',
    });
  }
});

app.get('/api/conversations/:id/history', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const messages = await storage.getConversationHistory(id);
    return res.json({ conversationId: id, messages });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve conversation' });
  }
});

// ============================================================================
// BELIEF ENDPOINTS
// ============================================================================

app.get('/api/beliefs', async (req: Request, res: Response) => {
  try {
    const beliefs = await storage.getAllBeliefs();
    const coherence = beliefs.length > 0
      ? beliefs.reduce((sum, b) => sum + b.weight, 0) / beliefs.length
      : 0;

    const response: BeliefNetworkResponse = {
      beliefs,
      connections: beliefs
        .slice(0, 5)
        .flatMap((b, i) =>
          beliefs
            .slice(i + 1, i + 2)
            .map(b2 => ({ from: b.id, to: b2.id }))
        ),
      coherenceScore: Math.round(coherence * 10),
    };

    return res.json(response);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve beliefs' });
  }
});

app.post('/api/beliefs', async (req: Request, res: Response) => {
  try {
    const { stance, domain, isCore } = req.body;

    if (!stance || !domain) {
      return res.status(400).json({ error: 'stance and domain required' });
    }

    const belief = await storage.createBelief(stance, domain, isCore || false);
    return res.status(201).json(belief);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to create belief' });
  }
});

app.patch('/api/beliefs/:id/weight', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { newWeight, reasoning } = req.body;

    if (newWeight === undefined) {
      return res.status(400).json({ error: 'newWeight required' });
    }

    await storage.updateBeliefWeight(id, newWeight, reasoning || 'Weight adjustment');
    const belief = await storage.getBelief(id);
    return res.json(belief);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update belief' });
  }
});

// ============================================================================
// LOGIC ENDPOINTS
// ============================================================================

app.get('/api/logic', async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const entries = await storage.getRecentLogicEntries(limit);
    return res.json({ entries, count: entries.length });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve logic entries' });
  }
});

app.get('/api/logic/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const entry = await storage.getLogicEntry(id);
    if (!entry) {
      return res.status(404).json({ error: 'Logic entry not found' });
    }
    return res.json(entry);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve logic entry' });
  }
});

// ============================================================================
// MEMORY ENDPOINTS
// ============================================================================

app.get('/api/memory', async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const entries = await storage.getRecentMemoryEntries(limit);
    return res.json({ entries, count: entries.length });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve memory entries' });
  }
});

app.get('/api/memory/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const entry = await storage.getMemoryEntry(id);
    if (!entry) {
      return res.status(404).json({ error: 'Memory entry not found' });
    }
    return res.json(entry);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve memory entry' });
  }
});

// ============================================================================
// INCONGRUENT PATTERN ENDPOINTS
// ============================================================================

app.get('/api/incongruent-log', async (req: Request, res: Response) => {
  try {
    const patterns = await storage.getIncongruentPatterns();
    const stats = {
      total: patterns.length,
      recent: patterns.filter(p => {
        const age = Date.now() - p.timestamp.getTime();
        return age < 7 * 24 * 60 * 60 * 1000;
      }).length,
    };
    return res.json({ patterns, stats });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve incongruent patterns' });
  }
});

// ============================================================================
// TENSION ENDPOINTS
// ========================================================================

app.get('/api/tensions', async (req: Request, res: Response) => {
  try {
    const tensions = await storage.getUnresolvedTensions();
    return res.json({
      tensions,
      count: tensions.length,
      mostFrequent: tensions.sort((a, b) => b.encounterCount - a.encounterCount).slice(0, 3),
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve tensions' });
  }
});

// ============================================================================
// SELF-REVIEW ENDPOINTS
// ========================================================================

app.post('/api/self-review', async (req: Request, res: Response) => {
  try {
    const logicEntries = await storage.getRecentLogicEntries(20);
    const memoryEntries = await storage.getRecentMemoryEntries(20);

    const advocateDominance = logicEntries.filter(l =>
      l.perspectives.some(p => p.role === 'Advocate' && p.strengthOfArgument > 7)
    ).length;

    const skepticDominance = logicEntries.filter(l =>
      l.perspectives.some(p => p.role === 'Skeptic' && p.strengthOfArgument > 7)
    ).length;

    const revisionRate =
      memoryEntries.filter(m =>
        m.selfInsights.some(i => i.category.includes('revision'))
      ).length / (memoryEntries.length || 1);

    const report: SelfReviewReport = {
      interactionsAnalyzed: logicEntries.length,
      advocateDominance: logicEntries.length > 0 ? advocateDominance / logicEntries.length : 0,
      skepticDominance: logicEntries.length > 0 ? skepticDominance / logicEntries.length : 0,
      revisionRate,
      interpretation:
        advocateDominance > skepticDominance * 1.5
          ? 'Leaning optimistic - Advocate stronger than Skeptic'
          : skepticDominance > advocateDominance * 1.5
            ? 'Leaning cautious - Skeptic stronger than Advocate'
            : 'Balanced deliberation - perspectives matched',
      recommendation:
        revisionRate > 0.3
          ? 'High revision rate - active belief evolution'
          : 'Stable beliefs - consider deeper challenges',
    };

    return res.json(report);
  } catch (err) {
    console.error('Self-review error:', err);
    return res.status(500).json({ error: 'Failed to generate self-review' });
  }
});

// ============================================================================
// SERVER START (async init)
// ============================================================================

const PORT = CONFIG.PORT;

async function startServer() {
  try {
    await storage.ensureInitialized();

    app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════════════════════╗
║           SOVERN BACKEND - Ready to Reason                ║
╚════════════════════════════════════════════════════════════╝

📍 Server: http://localhost:${PORT}
🧠 Ollama: ${CONFIG.OLLAMA_HOST}
📦 Model: ${CONFIG.OLLAMA_MODEL}
💾 Storage: ${DB_PATH}

API Endpoints:
  POST   /api/chat/messages          Send message to Sovern
  GET    /api/beliefs                View belief network
  POST   /api/beliefs                Create new belief
  GET    /api/logic                  View reasoning traces
  GET    /api/memory                 View learning history
  GET    /api/tensions               View unresolved tensions
  POST   /api/self-review            Analyze reasoning patterns
  GET    /health                     Server health

Start a conversation with a JSON POST to /api/chat/messages:
{
  "conversationId": "conv-123",
  "message": "What's the meaning of authenticity?",
  "userId": "user-123"
}
`);
    });
  } catch (err) {
    console.error('Failed to initialize storage or start server:', err);
    process.exit(1);
  }
}

startServer();

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n✓ Shutting down gracefully...');
  storage.close();
  process.exit(0);
});
