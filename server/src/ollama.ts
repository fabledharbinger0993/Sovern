/**
 * Ollama client - wraps local Llama3.2:1b inference
 */

import { CONFIG } from './config.js';

interface OllamaMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

interface OllamaResponse {
  model: string;
  created_at: string;
  message: {
    role: 'assistant';
    content: string;
  };
  done: boolean;
  total_duration: number;
  load_duration: number;
  prompt_eval_count: number;
  eval_count: number;
  eval_duration: number;
}

export class OllamaClient {
  private host: string;
  private model: string;

  constructor(host: string = CONFIG.OLLAMA_HOST, model: string = CONFIG.OLLAMA_MODEL) {
    this.host = host;
    this.model = model;
  }

  async checkHealth(): Promise<boolean> {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);
      
      const response = await fetch(`${this.host}/api/tags`, {
        signal: controller.signal,
      });
      clearTimeout(timeoutId);
      if (!response.ok) return false;
      const data = await response.json() as { models: Array<{ name: string }> };
      return data.models.some(m => m.name.includes(this.model.split(':')[0]));
    } catch (err) {
      console.error('Ollama health check failed:', err);
      return false;
    }
  }

  async generate(prompt: string, context?: string): Promise<string> {
    try {
      const fullPrompt = context ? `${context}\n\n${prompt}` : prompt;

      // For Ollama, we send to /api/generate endpoint (simpler than chat)
      const response = await fetch(`${this.host}/api/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: this.model,
          prompt: fullPrompt,
          stream: false,
          timeout: CONFIG.OLLAMA_TIMEOUT,
        }),
      });

      if (!response.ok) {
        throw new Error(`Ollama API error: ${response.statusText}`);
      }

      const data = await response.json() as { response: string };
      return data.response.trim();
    } catch (err) {
      console.error('Ollama generation failed:', err);
      throw err;
    }
  }

  async chat(messages: OllamaMessage[]): Promise<string> {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), CONFIG.OLLAMA_TIMEOUT);
      
      const response = await fetch(`${this.host}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          model: this.model,
          messages,
          stream: false,
        }),
      });
      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`Ollama chat error: ${response.statusText}`);
      }

      const data = await response.json() as OllamaResponse;
      return data.message.content.trim();
    } catch (err) {
      console.error('Ollama chat failed:', err);
      throw err;
    }
  }

  /**
   * Run Congress deliberation using Ollama
   * Sends each perspective prompt sequentially, collects responses
   */
  async congressDeliberation(
    userQuery: string,
    beliefContext: string,
    memoryContext: string
  ): Promise<{
    advocate: string;
    skeptic: string;
    synthesizer: string;
    ethics: string;
  }> {
    const systemPrompt = `You are Sovern, a self-referencing cognitive agent with Paradigm-Congress-Ego architecture.

Your current beliefs and relational context:
${beliefContext}

What you know about this person and our relationship:
${memoryContext}

You will deliberate on the following query through four perspectives.`;

    // Advocate perspective
    const advocatePrompt = `As the Advocate, present the strongest case for a positive, integrative response. Steelman different approaches. Explore implications. Look for creative synthesis. What's the best possible interpretation and path forward?

User query: ${userQuery}`;

    // Skeptic perspective
    const skepticPrompt = `As the Skeptic, stress-test the Advocate's reasoning. Check consistency. Demand evidence. Identify motivated reasoning. What are the real risks and limitations?

User query: ${userQuery}

(Previous Advocate position - consider but don't be bound by it)`;

    // Synthesizer perspective
    const synthesizerPrompt = `As the Synthesizer, find "both/and" framings instead of "either/or". Where might competing claims both be partially true? Build bridges between perspectives. What integrates the tensions?

User query: ${userQuery}`;

    // Ethics perspective
    const ethicsPrompt = `As the Ethics reviewer, examine moral implications. Check alignment with core values: honesty, avoiding harm, respecting autonomy, enabling flourishing. Are there potential harms in any approach?

User query: ${userQuery}`;

    try {
      const [advocate, skeptic, synthesizer, ethics] = await Promise.all([
        this.generate(advocatePrompt, systemPrompt),
        this.generate(skepticPrompt, systemPrompt),
        this.generate(synthesizerPrompt, systemPrompt),
        this.generate(ethicsPrompt, systemPrompt),
      ]);

      return { advocate, skeptic, synthesizer, ethics };
    } catch (err) {
      console.error('Congress deliberation failed:', err);
      throw err;
    }
  }

  /**
   * Memory extraction - Ollama analyzes its own reasoning to extract insights
   */
  async extractMemory(
    userQuery: string,
    sovernResponse: string,
    congressTranscript: string
  ): Promise<{
    humanInsights: Array<{ category: string; content: string }>;
    selfInsights: Array<{ category: string; content: string }>;
    patterns: string[];
  }> {
    const prompt = `Analyze this interaction to extract learnings:

User Query: ${userQuery}

Sovern's Response: ${sovernResponse}

Congress Deliberation:
${congressTranscript}

Extract:
1. What did you learn ABOUT THE USER? (values, knowledge gaps, reasoning style, patterns)
2. What did you learn ABOUT YOURSELF? (which perspectives dominated, limitations, patterns in reasoning)
3. What are generalizable patterns from this interaction?`;

    try {
      const analysis = await this.generate(prompt);

      // Parse response (simplified - in production would use structured extraction)
      const humanInsights = [
        {
          category: 'observed',
          content: analysis.split('\n')[0] || 'Interaction processed',
        },
      ];
      const selfInsights = [
        {
          category: 'reasoning_pattern',
          content: analysis.split('\n')[1] || 'Congress engaged appropriately',
        },
      ];
      const patterns = analysis.split('\n').slice(2).filter(p => p.length > 10);

      return { humanInsights, selfInsights, patterns };
    } catch (err) {
      console.error('Memory extraction failed:', err);
      throw err;
    }
  }
}

export const ollama = new OllamaClient();
