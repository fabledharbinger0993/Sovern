/**
 * Core type definitions for Sovern's Paradigm-Congress-Ego architecture
 */

export type BeliefDomain = 'SELF' | 'KNOWLEDGE' | 'ETHICS' | 'RELATIONAL' | 'META';

export type PerspectiveRole = 'Advocate' | 'Skeptic' | 'Synthesizer' | 'Ethics';

export type ReasoningStepType =
  | 'analysis'
  | 'concern'
  | 'debate'
  | 'insight'
  | 'revision'
  | 'decision';

export type CandidateResponseStatus = 'rejected' | 'considering' | 'selected';

export type RoutingStrategy = 'direct' | 'socratic' | 'analytical' | 'empathetic' | 'exploratory';

// ============================================================================
// BELIEF SYSTEM TYPES
// ============================================================================

export interface BeliefRevision {
  timestamp: Date;
  oldWeight: number;
  newWeight: number;
  revisionType: 'challenge' | 'strengthen' | 'revise' | 'weaken';
  reasoning: string;
}

export interface BeliefNode {
  id: string;
  stance: string; // e.g., "Authenticity", "Growth"
  domain: BeliefDomain;
  weight: number; // 1-10 scale
  reasoning: string;
  revisionHistory: BeliefRevision[];
  isCore: boolean; // Original 7 vs learned
  connectionIds: string[];
}

export interface BeliefSystem {
  id: string;
  beliefs: Map<string, BeliefNode>;
  createdAt: Date;
  updatedAt: Date;

  // Methods
  addBelief(stance: string, domain: BeliefDomain, isCore: boolean): string;
  getBelief(id: string): BeliefNode | undefined;
  setBeliefsWeight(id: string, newWeight: number, reason: string): void;
  coherenceScore(): number;
}

// ============================================================================
// CONGRESS SYSTEM TYPES
// ============================================================================

export interface ReasoningStep {
  type: ReasoningStepType;
  timestamp: Date;
  content: string;
  revisionData?: {
    original: string;
    revised: string;
    reason: string;
  };
}

export interface CongressPerspective {
  role: PerspectiveRole;
  position: string;
  reasoning: string;
  strengthOfArgument: number; // 1-10
}

export interface CandidateResponse {
  id: string;
  draftNumber: number;
  content: string;
  status: CandidateResponseStatus;
  rejectionReason?: string;
}

export interface LogicEntry {
  id: string;
  timestamp: Date;
  userQuery: string;
  paradigmRouting: RoutingStrategy;
  complexityWeight: number; // 1-9 scale
  congressEngaged: boolean;
  reasoningSteps: ReasoningStep[];
  perspectives: CongressPerspective[];
  candidateResponses: CandidateResponse[];
  profoundInsights: string[]; // Tagged with ✨
  finalResponse: string;
  finalReasoning: string;
}

// ============================================================================
// MEMORY SYSTEM TYPES
// ============================================================================

export interface Insight {
  category: string; // e.g., "preference", "value", "knowledge_gap", "reasoning_style"
  content: string;
  confidence: number; // 0-100
  evidenceFromLogic?: string; // Reference to LogicEntry reasoning
}

export interface MemoryEntry {
  id: string;
  timestamp: Date;
  userQuery: string;
  sovernResponse: string;
  paradigmRouting: RoutingStrategy;
  congressEngaged: boolean;
  humanInsights: Insight[];
  selfInsights: Insight[];
  learnedPatterns: string[];
  dataSourcesAccessed: string[];
  researchNotes: string;
  logicEntryId?: string;
}

// ============================================================================
// RELATIONAL & EGO TYPES
// ============================================================================

export interface IncongruentPatternLog {
  id: string;
  messageId: string;
  congressConclusion: string;
  egoExpression: string;
  reasoning: string;
  relationalContext: string;
  timestamp: Date;
}

export interface EpistemicTension {
  id: string;
  description: string;
  belief1: string;
  belief2: string;
  firstNoticed: Date;
  lastEncountered: Date;
  encounterCount: number;
  resolved: boolean;
  resolutionDate?: Date;
  resolutionReasoning?: string;
}

export interface UserRelationalContext {
  userId: string;
  name: string;
  trustLevel: 'establishing' | 'developing' | 'established';
  interactionPatterns: string[];
  sharedHistory: string[];
  relationalObligations: string[];
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================================
// CHAT & MESSAGE TYPES
// ============================================================================

export interface ChatMessage {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  logicEntryId?: string; // Links to reasoning that produced response
  memoryEntryId?: string; // Links to learning that was extracted
}

export interface SynthesisOutput {
  logicEntry: LogicEntry;
  memoryEntry: MemoryEntry;
  beliefUpdates: Array<{
    beliefId: string;
    stance: string;
    revisionType: 'challenge' | 'strengthen' | 'revise' | 'weaken';
    revisionReasoning: string;
  }>;
  incongruentLog: IncongruentPatternLog | null;
  epistemicTensions: EpistemicTension[];
}

// ============================================================================
// API REQUEST/RESPONSE TYPES
// ============================================================================

export interface ChatRequest {
  conversationId: string;
  message: string;
  userId?: string;
  context?: {
    paradigmContext?: string;
    beliefContext?: string;
    memoryContext?: string;
  };
}

export interface ChatResponse {
  id: string;
  conversationId: string;
  message: string;
  timestamp: Date;
  logicEntry?: LogicEntry;
  memoryEntry?: MemoryEntry;
  beliefUpdates?: Array<{
    beliefId: string;
    stance: string;
    revisionType: 'challenge' | 'strengthen' | 'revise' | 'weaken';
    revisionReasoning: string;
  }>;
}

export interface BeliefNetworkResponse {
  beliefs: BeliefNode[];
  connections: Array<{ from: string; to: string }>;
  coherenceScore: number;
}

export interface ConversationHistory {
  conversationId: string;
  messages: ChatMessage[];
  logicEntries: LogicEntry[];
  memoryEntries: MemoryEntry[];
}

export interface SelfReviewReport {
  interactionsAnalyzed: number;
  advocateDominance: number;
  skepticDominance: number;
  revisionRate: number;
  interpretation: string;
  recommendation: string;
}
