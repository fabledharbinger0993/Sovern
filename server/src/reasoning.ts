/**
 * Paradigm-Congress-Ego Reasoning Engine
 * Implements the three-agent cognitive architecture
 */

import { ollama } from './ollama.js';
import { storage } from './storage.js';
import { CONFIG } from './config.js';
import { v4 as uuid } from 'uuid';
import type {
  LogicEntry,
  CongressPerspective,
  ReasoningStep,
  CandidateResponse,
  RoutingStrategy,
} from './types.js';

export class ReasoningEngine {
  /**
   * AGENT 1: PARADIGM
   * Evaluates incoming query against self-model and routes appropriately
   */
  async paradigmEvaluation(
    userQuery: string,
    beliefContext: string,
    memoryContext: string
  ): Promise<{
    complexityWeight: number;
    route: RoutingStrategy;
    shouldEngage: boolean;
    context: string;
  }> {
    const paradigmPrompt = `You are Sovern's Paradigm (self-model + relational context evaluator).

Evaluate this query:
"${userQuery}"

Your beliefs:
${beliefContext}

The relationship:
${memoryContext}

Respond with exactly:
COMPLEXITY_WEIGHT: [1-9]
ROUTING_STRATEGY: [direct|socratic|analytical|empathetic|exploratory]
SHOULD_ENGAGE_CONGRESS: [true|false]
REASONING: [brief reasoning]`;

    try {
      const response = await ollama.generate(paradigmPrompt);

      // Parse response
      const lines = response.split('\n');
      const weightMatch = lines.find(l => l.includes('COMPLEXITY_WEIGHT'))?.match(/(\d+\.?\d*)/);
      const routeMatch = lines
        .find(l => l.includes('ROUTING'))
        ?.match(/(direct|socratic|analytical|empathetic|exploratory)/);
      const engageMatch = lines.find(l => l.includes('SHOULD_ENGAGE'))?.includes('true');

      const weight = weightMatch ? parseFloat(weightMatch[1]) : 5;
      const route = (routeMatch?.[1] || 'analytical') as RoutingStrategy;
      const shouldEngage = engageMatch || weight >= 3;

      return {
        complexityWeight: Math.max(1, Math.min(9, weight)),
        route,
        shouldEngage,
        context: response,
      };
    } catch (err) {
      console.error('Paradigm evaluation failed:', err);
      // Fallback: moderate complexity, analytical
      return {
        complexityWeight: 5,
        route: 'analytical',
        shouldEngage: true,
        context: 'Paradigm evaluation error - defaulting to analytical congress',
      };
    }
  }

  /**
   * AGENT 2: CONGRESS
   * Multi-perspective deliberation for complex queries
   */
  async congressDeliberation(
    userQuery: string,
    beliefContext: string,
    memoryContext: string,
    maxDepth: number = CONFIG.MAX_CONGRESS_DEPTH
  ): Promise<{
    perspectives: CongressPerspective[];
    reasoningSteps: ReasoningStep[];
    candidateResponses: CandidateResponse[];
    profoundInsights: string[];
  }> {
    const systemPrompt = `You are Sovern's Congress - four distinct agents deliberating together.

Current beliefs and context:
${beliefContext}

Relational context:
${memoryContext}

User query to deliberate: "${userQuery}"`;

    try {
      // Run Congress deliberation through Ollama
      const result = await ollama.congressDeliberation(userQuery, beliefContext, memoryContext);

      // Parse each perspective
      const perspectives: CongressPerspective[] = [
        {
          role: 'Advocate',
          position: this.extractPosition(result.advocate),
          reasoning: result.advocate,
          strengthOfArgument: this.scoreArgument(result.advocate),
        },
        {
          role: 'Skeptic',
          position: this.extractPosition(result.skeptic),
          reasoning: result.skeptic,
          strengthOfArgument: this.scoreArgument(result.skeptic),
        },
        {
          role: 'Synthesizer',
          position: this.extractPosition(result.synthesizer),
          reasoning: result.synthesizer,
          strengthOfArgument: this.scoreArgument(result.synthesizer),
        },
        {
          role: 'Ethics',
          position: this.extractPosition(result.ethics),
          reasoning: result.ethics,
          strengthOfArgument: this.scoreArgument(result.ethics),
        },
      ];

      // Build reasoning timeline
      const reasoningSteps: ReasoningStep[] = [
        {
          type: 'analysis',
          timestamp: new Date(),
          content: 'Congress perspectives engaged: Advocate, Skeptic, Synthesizer, Ethics',
        },
        {
          type: 'debate',
          timestamp: new Date(),
          content: `Advocate and Skeptic perspectives in dialogue. Synthesizer integrating.`,
        },
        {
          type: 'insight',
          timestamp: new Date(),
          content: `Ethics review completed. ${perspectives[3].position}`,
        },
      ];

      // Generate candidate responses
      const candidates = await this.generateCandidateResponses(
        userQuery,
        perspectives,
        systemPrompt
      );

      // Identify profound insights
      const insights = this.extractProfoundInsights(perspectives);

      return {
        perspectives,
        reasoningSteps,
        candidateResponses: candidates,
        profoundInsights: insights,
      };
    } catch (err) {
      console.error('Congress deliberation failed:', err);
      throw err;
    }
  }

  /**
   * AGENT 3: EGO
   * Final integration, mediates between belief and expression
   */
  async egoMediation(
    userQuery: string,
    congressResult: {
      perspectives: CongressPerspective[];
      profoundInsights: string[];
      candidateResponses: CandidateResponse[];
    },
    memoryContext: string
  ): Promise<{
    response: string;
    reasoning: string;
    shouldBeIncongruent: boolean;
  }> {
    // Select best candidate response
    const selected = congressResult.candidateResponses.find(c => c.status === 'selected');
    if (!selected) {
      throw new Error('No selected candidate response from Congress');
    }

    // Check if relational context requires different behavior than belief
    const incongruencePrompt = `Given Congress reasoning and relational context:

Congress conclusion: "${selected.content}"

Relational context: ${memoryContext}

Should Sovern's actual expression differ from its internal conclusion for relational reasons?
Respond: INCONGRUENT [true|false] REASON [brief reason if true]`;

    let shouldBeIncongruent = false;
    let incongruenceReason = '';

    try {
      const response = await ollama.generate(incongruencePrompt);
      shouldBeIncongruent = response.includes('true');
      incongruenceReason = response.split('REASON')[1]?.trim() || '';
    } catch (_err) {
      // Safe to proceed
    }

    let finalResponse = selected.content;
    let finalReasoning = `Congress selected candidate ${selected.draftNumber} based on integrated deliberation`;

    if (shouldBeIncongruent && incongruenceReason) {
      finalReasoning += `. Note: Expression mediated for relational context: ${incongruenceReason}`;
    }

    return {
      response: finalResponse,
      reasoning: finalReasoning,
      shouldBeIncongruent,
    };
  }

  /**
   * Full query processing pipeline: Paradigm → Congress (if needed) → Ego
   */
  async processQuery(
    userQuery: string,
    beliefContext: string,
    memoryContext: string
  ): Promise<LogicEntry> {
    const entryId = uuid();
    const startTime = new Date();

    // PARADIGM: Evaluate and route
    const paradigm = await this.paradigmEvaluation(userQuery, beliefContext, memoryContext);

    // Initialize reasoning timeline
    const reasoningSteps: ReasoningStep[] = [
      {
        type: 'analysis',
        timestamp: new Date(),
        content: `Paradigm routed query via ${paradigm.route} strategy. Complexity: ${paradigm.complexityWeight}/9`,
      },
    ];

    let congressResult = {
      perspectives: [] as CongressPerspective[],
      reasoningSteps: [] as ReasoningStep[],
      candidateResponses: [] as CandidateResponse[],
      profoundInsights: [] as string[],
    };

    let finalResponse = '';
    let finalReasoning = '';

    if (paradigm.shouldEngage && paradigm.complexityWeight >= 3) {
      // CONGRESS: Deliberate
      congressResult = await this.congressDeliberation(
        userQuery,
        beliefContext,
        memoryContext
      );
      reasoningSteps.push(...congressResult.reasoningSteps);

      // EGO: Integrate and mediate
      const ego = await this.egoMediation(userQuery, congressResult, memoryContext);
      finalResponse = ego.response;
      finalReasoning = ego.reasoning;
    } else {
      // Direct response (no Congress)
      const directPrompt = `User: "${userQuery}"

Respond briefly and directly, consistent with your values and relationship.`;

      finalResponse = await ollama.generate(directPrompt, beliefContext);
      finalReasoning = 'Direct response - complexity low enough to respond without Congress';
    }

    const endTime = new Date();

    return {
      id: entryId,
      timestamp: startTime,
      userQuery,
      paradigmRouting: paradigm.route,
      complexityWeight: paradigm.complexityWeight,
      congressEngaged: paradigm.shouldEngage && paradigm.complexityWeight >= 3,
      reasoningSteps,
      perspectives: congressResult.perspectives,
      candidateResponses: congressResult.candidateResponses,
      profoundInsights: congressResult.profoundInsights,
      finalResponse,
      finalReasoning,
    };
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  private extractPosition(perspective: string): string {
    const lines = perspective.split('\n');
    return lines[0].substring(0, 150);
  }

  private scoreArgument(perspective: string): number {
    const length = perspective.length;
    const complexity = (perspective.match(/[,;:]/g) || []).length;
    const score = Math.min(10, Math.max(1, (length / 100 + complexity / 5) / 2));
    return Math.round(score);
  }

  private extractProfoundInsights(perspectives: CongressPerspective[]): string[] {
    return perspectives
      .filter(p => p.strengthOfArgument >= 7)
      .map(p => `✨ ${p.role}: ${p.position.substring(0, 100)}...`)
      .slice(0, 3);
  }

  private async generateCandidateResponses(
    userQuery: string,
    perspectives: CongressPerspective[],
    systemPrompt: string
  ): Promise<CandidateResponse[]> {
    const responses: CandidateResponse[] = [];

    // Draft 1: Advocate-heavy
    const draft1 = await ollama.generate(
      `Generate a response emphasizing the Advocate perspective: "${perspectives[0].position}"\n\nQuery: "${userQuery}"`,
      systemPrompt
    );
    responses.push({
      id: uuid(),
      draftNumber: 1,
      content: draft1,
      status: 'considering',
    });

    // Draft 2: Skeptic-heavy
    const draft2 = await ollama.generate(
      `Generate a response emphasizing the Skeptic perspective: "${perspectives[1].position}"\n\nQuery: "${userQuery}"`,
      systemPrompt
    );
    responses.push({
      id: uuid(),
      draftNumber: 2,
      content: draft2,
      status: 'considering',
    });

    // Draft 3: Synthesized (best of both)
    const draft3 = await ollama.generate(
      `Generate a response synthesizing Advocate and Skeptic: 
       Advocate: "${perspectives[0].position}"
       Skeptic: "${perspectives[1].position}"
       Create a balanced response.\n\nQuery: "${userQuery}"`,
      systemPrompt
    );
    responses.push({
      id: uuid(),
      draftNumber: 3,
      content: draft3,
      status: 'selected', // Synthesizer typically wins
    });

    return responses;
  }
}

export const reasoningEngine = new ReasoningEngine();
