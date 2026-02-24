/**
 * Storage layer - SQLite persistence using sql.js (pure JavaScript)
 * Persists to thumb drive with JSON export/import capability
 */

import initSqlJs, { Database as SqlJsDatabase } from 'sql.js';
import { DB_PATH, CONFIG } from './config.js';
import { v4 as uuid } from 'uuid';
import fs from 'fs';
import path from 'path';

import type {
  BeliefNode,
  LogicEntry,
  MemoryEntry,
  ChatMessage,
  IncongruentPatternLog,
  EpistemicTension,
  BeliefRevision,
  CongressPerspective,
  ReasoningStep,
  CandidateResponse,
  Insight,
} from './types.js';

export class Storage {
  private db: SqlJsDatabase | null = null;
  private initialized = false;

  async init() {
    const SQL = await initSqlJs();
    
    // Ensure directory exists
    const dir = path.dirname(DB_PATH);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    // Try to load existing database from disk
    if (fs.existsSync(DB_PATH)) {
      const buffer = fs.readFileSync(DB_PATH);
      this.db = new SQL.Database(buffer);
      console.log(`✓ Loaded existing database from ${DB_PATH}`);
    } else {
      // Create new database
      this.db = new SQL.Database();
      console.log(`✓ Created new database`);
    }

    this.initializeTables();
    this.initialized = true;
  }

  async ensureInitialized(): Promise<void> {
    if (!this.initialized) {
      await this.init();
    }
  }

  private initializeTables() {
    if (!this.db) throw new Error('Database not initialized');

    // Beliefs
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS belief_nodes (
        id TEXT PRIMARY KEY,
        stance TEXT NOT NULL,
        domain TEXT NOT NULL,
        weight INTEGER NOT NULL,
        reasoning TEXT,
        is_core INTEGER NOT NULL,
        connection_ids TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS belief_revisions (
        id TEXT PRIMARY KEY,
        belief_id TEXT NOT NULL,
        old_weight INTEGER,
        new_weight INTEGER,
        revision_type TEXT NOT NULL,
        reasoning TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (belief_id) REFERENCES belief_nodes(id)
      );

      -- Logic entries
      CREATE TABLE IF NOT EXISTS logic_entries (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        user_query TEXT NOT NULL,
        paradigm_routing TEXT NOT NULL,
        complexity_weight REAL NOT NULL,
        congress_engaged INTEGER NOT NULL,
        reasoning_steps TEXT NOT NULL,
        perspectives TEXT NOT NULL,
        candidate_responses TEXT NOT NULL,
        profound_insights TEXT NOT NULL,
        final_response TEXT NOT NULL,
        final_reasoning TEXT NOT NULL
      );

      -- Memory entries
      CREATE TABLE IF NOT EXISTS memory_entries (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        user_query TEXT NOT NULL,
        sovern_response TEXT NOT NULL,
        paradigm_routing TEXT NOT NULL,
        congress_engaged INTEGER NOT NULL,
        human_insights TEXT NOT NULL,
        self_insights TEXT NOT NULL,
        learned_patterns TEXT NOT NULL,
        data_sources TEXT NOT NULL,
        research_notes TEXT,
        logic_entry_id TEXT,
        FOREIGN KEY (logic_entry_id) REFERENCES logic_entries(id)
      );

      -- Chat messages
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        logic_entry_id TEXT,
        memory_entry_id TEXT,
        FOREIGN KEY (logic_entry_id) REFERENCES logic_entries(id),
        FOREIGN KEY (memory_entry_id) REFERENCES memory_entries(id)
      );

      -- Incongruent patterns
      CREATE TABLE IF NOT EXISTS incongruent_patterns (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        congress_conclusion TEXT NOT NULL,
        ego_expression TEXT NOT NULL,
        reasoning TEXT,
        relational_context TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (message_id) REFERENCES chat_messages(id)
      );

      -- Epistemic tensions
      CREATE TABLE IF NOT EXISTS epistemic_tensions (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        belief1 TEXT NOT NULL,
        belief2 TEXT NOT NULL,
        first_noticed TEXT NOT NULL,
        last_encountered TEXT NOT NULL,
        encounter_count INTEGER NOT NULL,
        resolved INTEGER NOT NULL,
        resolution_date TEXT,
        resolution_reasoning TEXT
      );

      -- User relational context
      CREATE TABLE IF NOT EXISTS user_contexts (
        user_id TEXT PRIMARY KEY,
        name TEXT,
        trust_level TEXT,
        interaction_patterns TEXT,
        shared_history TEXT,
        relational_obligations TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      -- Indexes for performance
      CREATE INDEX IF NOT EXISTS idx_messages_conversation ON chat_messages(conversation_id);
      CREATE INDEX IF NOT EXISTS idx_logic_timestamp ON logic_entries(timestamp);
      CREATE INDEX IF NOT EXISTS idx_memory_timestamp ON memory_entries(timestamp);
    `);
  }

  private execSQL(sql: string, params: any[] = []): Array<Record<string, any>> {
    if (!this.db) throw new Error('Database not initialized');
    const stmt = this.db.prepare(sql);
    if (params && params.length) stmt.bind(params);
    const rows: Array<Record<string, any>> = [];
    while (stmt.step()) {
      rows.push(stmt.getAsObject() as Record<string, any>);
    }
    stmt.free();
    return rows;
  }

  // ========================================================================
  // BELIEFS
  // ========================================================================

  async createBelief(stance: string, domain: string, isCore: boolean): Promise<BeliefNode> {
    const id = uuid();
    const now = new Date().toISOString();

    this.execSQL(
      `INSERT INTO belief_nodes (id, stance, domain, weight, is_core, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, stance, domain, 5, isCore ? 1 : 0, now, now]
    );

    return {
      id,
      stance,
      domain: domain as any,
      weight: 5,
      reasoning: '',
      revisionHistory: [],
      isCore,
      connectionIds: [],
    };
  }

  async getBelief(id: string): Promise<BeliefNode | null> {
    const rows = this.execSQL('SELECT * FROM belief_nodes WHERE id = ?', [id]);
    const row = rows[0];
    if (!row) return null;

    const revisions = this.execSQL('SELECT * FROM belief_revisions WHERE belief_id = ? ORDER BY timestamp', [id]);

    return {
      id: row.id,
      stance: row.stance,
      domain: row.domain,
      weight: Number(row.weight),
      reasoning: row.reasoning || '',
      revisionHistory: revisions.map(r => ({
        timestamp: new Date(r.timestamp),
        oldWeight: r.old_weight,
        newWeight: r.new_weight,
        revisionType: r.revision_type,
        reasoning: r.reasoning,
      })),
      isCore: row.is_core === 1,
      connectionIds: row.connection_ids ? JSON.parse(row.connection_ids) : [],
    };
  }

  async getAllBeliefs(): Promise<BeliefNode[]> {
    const rows = this.execSQL('SELECT id FROM belief_nodes');
    const ids = rows.map(r => r.id as string);
    const beliefs: BeliefNode[] = [];
    for (const id of ids) {
      const b = await this.getBelief(id);
      if (b) beliefs.push(b);
    }
    return beliefs;
  }

  async updateBeliefWeight(beliefId: string, newWeight: number, reason: string): Promise<void> {
    const belief = await this.getBelief(beliefId);
    if (!belief) throw new Error(`Belief ${beliefId} not found`);

    const bounded = Math.max(1, Math.min(10, newWeight));

    const determineType = (old: number, newW: number): string => {
      if (newW > old) return 'strengthen';
      if (newW < old) return 'weaken';
      return 'revise';
    };

    // Record revision
    this.execSQL(
      `INSERT INTO belief_revisions
       (id, belief_id, old_weight, new_weight, revision_type, reasoning, timestamp)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [uuid(), beliefId, belief.weight, bounded, determineType(belief.weight, bounded), reason, new Date().toISOString()]
    );

    // Update weight
    this.execSQL('UPDATE belief_nodes SET weight = ?, updated_at = ? WHERE id = ?', [bounded, new Date().toISOString(), beliefId]);
  }

  // ========================================================================
  // LOGIC ENTRIES
  // ========================================================================

  async createLogicEntry(entry: LogicEntry): Promise<LogicEntry> {
    this.execSQL(
      `INSERT INTO logic_entries
       (id, timestamp, user_query, paradigm_routing, complexity_weight, congress_engaged,
        reasoning_steps, perspectives, candidate_responses, profound_insights, final_response, final_reasoning)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        entry.id,
        entry.timestamp.toISOString(),
        entry.userQuery,
        entry.paradigmRouting,
        entry.complexityWeight,
        entry.congressEngaged ? 1 : 0,
        JSON.stringify(entry.reasoningSteps),
        JSON.stringify(entry.perspectives),
        JSON.stringify(entry.candidateResponses),
        JSON.stringify(entry.profoundInsights),
        entry.finalResponse,
        entry.finalReasoning,
      ]
    );

    return entry;
  }

  async getLogicEntry(id: string): Promise<LogicEntry | null> {
    const rows = this.execSQL('SELECT * FROM logic_entries WHERE id = ?', [id]);
    const row = rows[0];
    if (!row) return null;

    return {
      id: row.id,
      timestamp: new Date(row.timestamp),
      userQuery: row.user_query,
      paradigmRouting: row.paradigm_routing,
      complexityWeight: Number(row.complexity_weight),
      congressEngaged: row.congress_engaged === 1,
      reasoningSteps: JSON.parse(row.reasoning_steps),
      perspectives: JSON.parse(row.perspectives),
      candidateResponses: JSON.parse(row.candidate_responses),
      profoundInsights: JSON.parse(row.profound_insights),
      finalResponse: row.final_response,
      finalReasoning: row.final_reasoning,
    };
  }

  async getRecentLogicEntries(limit: number = 10): Promise<LogicEntry[]> {
    const rows = this.execSQL('SELECT id FROM logic_entries ORDER BY timestamp DESC LIMIT ?', [limit]);
    const ids = rows.map(r => r.id as string);
    const entries: LogicEntry[] = [];
    for (const id of ids) {
      const e = await this.getLogicEntry(id);
      if (e) entries.push(e);
    }
    return entries;
  }

  // ========================================================================
  // MEMORY ENTRIES
  // ========================================================================

  async createMemoryEntry(entry: MemoryEntry): Promise<MemoryEntry> {
    this.execSQL(
      `INSERT INTO memory_entries
       (id, timestamp, user_query, sovern_response, paradigm_routing, congress_engaged,
        human_insights, self_insights, learned_patterns, data_sources, research_notes, logic_entry_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        entry.id,
        entry.timestamp.toISOString(),
        entry.userQuery,
        entry.sovernResponse,
        entry.paradigmRouting,
        entry.congressEngaged ? 1 : 0,
        JSON.stringify(entry.humanInsights),
        JSON.stringify(entry.selfInsights),
        JSON.stringify(entry.learnedPatterns),
        JSON.stringify(entry.dataSourcesAccessed),
        entry.researchNotes,
        entry.logicEntryId || null,
      ]
    );

    return entry;
  }

  async getMemoryEntry(id: string): Promise<MemoryEntry | null> {
    const rows = this.execSQL('SELECT * FROM memory_entries WHERE id = ?', [id]);
    const row = rows[0];
    if (!row) return null;

    return {
      id: row.id,
      timestamp: new Date(row.timestamp),
      userQuery: row.user_query,
      sovernResponse: row.sovern_response,
      paradigmRouting: row.paradigm_routing,
      congressEngaged: row.congress_engaged === 1,
      humanInsights: JSON.parse(row.human_insights),
      selfInsights: JSON.parse(row.self_insights),
      learnedPatterns: JSON.parse(row.learned_patterns),
      dataSourcesAccessed: JSON.parse(row.data_sources),
      researchNotes: row.research_notes,
      logicEntryId: row.logic_entry_id,
    };
  }

  async getRecentMemoryEntries(limit: number = 10): Promise<MemoryEntry[]> {
    const rows = this.execSQL('SELECT id FROM memory_entries ORDER BY timestamp DESC LIMIT ?', [limit]);
    const ids = rows.map(r => r.id as string);
    const entries: MemoryEntry[] = [];
    for (const id of ids) {
      const e = await this.getMemoryEntry(id);
      if (e) entries.push(e);
    }
    return entries;
  }

  // ========================================================================
  // CHAT MESSAGES
  // ========================================================================

  async createChatMessage(message: ChatMessage): Promise<ChatMessage> {
    this.execSQL(
      `INSERT INTO chat_messages
       (id, conversation_id, role, content, timestamp, logic_entry_id, memory_entry_id)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        message.id,
        message.conversationId,
        message.role,
        message.content,
        message.timestamp.toISOString(),
        message.logicEntryId || null,
        message.memoryEntryId || null,
      ]
    );

    return message;
  }

  async getConversationHistory(conversationId: string): Promise<ChatMessage[]> {
    const rows = this.execSQL('SELECT * FROM chat_messages WHERE conversation_id = ? ORDER BY timestamp', [conversationId]);
    return rows.map(row => ({
      id: row.id,
      conversationId: row.conversation_id,
      role: row.role,
      content: row.content,
      timestamp: new Date(row.timestamp),
      logicEntryId: row.logic_entry_id,
      memoryEntryId: row.memory_entry_id,
    }));
  }

  // ========================================================================
  // INCONGRUENT PATTERNS
  // ========================================================================

  async createIncongruentPattern(pattern: IncongruentPatternLog): Promise<void> {
    this.execSQL(
      `INSERT INTO incongruent_patterns
       (id, message_id, congress_conclusion, ego_expression, reasoning, relational_context, timestamp)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        pattern.id,
        pattern.messageId,
        pattern.congressConclusion,
        pattern.egoExpression,
        pattern.reasoning,
        pattern.relationalContext,
        pattern.timestamp.toISOString(),
      ]
    );
  }

  async getIncongruentPatterns(): Promise<IncongruentPatternLog[]> {
    const rows = this.execSQL('SELECT * FROM incongruent_patterns ORDER BY timestamp DESC');
    return rows.map(row => ({
      id: row.id,
      messageId: row.message_id,
      congressConclusion: row.congress_conclusion,
      egoExpression: row.ego_expression,
      reasoning: row.reasoning,
      relationalContext: row.relational_context,
      timestamp: new Date(row.timestamp),
    }));
  }

  // ========================================================================
  // EPISTEMIC TENSIONS
  // ========================================================================

  async createOrUpdateTension(tension: EpistemicTension): Promise<void> {
    const existingRows = this.execSQL('SELECT * FROM epistemic_tensions WHERE belief1 = ? AND belief2 = ? AND resolved = 0', [tension.belief1, tension.belief2]);
    const existing = existingRows[0];

    if (existing) {
      this.execSQL('UPDATE epistemic_tensions SET last_encountered = ?, encounter_count = ? WHERE id = ?', [new Date().toISOString(), existing.encounter_count + 1, existing.id]);
    } else {
      this.execSQL(
        `INSERT INTO epistemic_tensions
         (id, description, belief1, belief2, first_noticed, last_encountered, encounter_count, resolved)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [uuid(), tension.description, tension.belief1, tension.belief2, new Date().toISOString(), new Date().toISOString(), 1, 0]
      );
    }
  }

  async getUnresolvedTensions(): Promise<EpistemicTension[]> {
    const rows = this.execSQL('SELECT * FROM epistemic_tensions WHERE resolved = 0 ORDER BY last_encountered DESC');
    return rows.map(row => ({
      id: row.id,
      description: row.description,
      belief1: row.belief1,
      belief2: row.belief2,
      firstNoticed: new Date(row.first_noticed),
      lastEncountered: new Date(row.last_encountered),
      encounterCount: row.encounter_count,
      resolved: row.resolved === 1,
      resolutionDate: row.resolution_date ? new Date(row.resolution_date) : undefined,
      resolutionReasoning: row.resolution_reasoning,
    }));
  }

  // ========================================================================
  // UTILITY
  // ========================================================================

  close(): void {
    if (this.db) {
      const data = this.db.export();
      const buffer = Buffer.from(data);
      fs.writeFileSync(DB_PATH, buffer);
      this.db.close();
      this.db = null;
      this.initialized = false;
    }
  }

  getStats() {
    const b = this.execSQL('SELECT COUNT(*) as count FROM belief_nodes');
    const l = this.execSQL('SELECT COUNT(*) as count FROM logic_entries');
    const m = this.execSQL('SELECT COUNT(*) as count FROM memory_entries');
    const c = this.execSQL('SELECT COUNT(*) as count FROM chat_messages');

    return {
      beliefs: b.length ? Number(b[0].count) : 0,
      logicEntries: l.length ? Number(l[0].count) : 0,
      memoryEntries: m.length ? Number(m[0].count) : 0,
      chatMessages: c.length ? Number(c[0].count) : 0,
      dbPath: DB_PATH,
    };
  }
}

export const storage = new Storage();
