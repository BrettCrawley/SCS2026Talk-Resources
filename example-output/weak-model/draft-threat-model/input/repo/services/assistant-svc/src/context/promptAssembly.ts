import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { forWorkspace } from './workspaceConfig.js';
import type { ConversationState, RetrievedChunk } from '../types.js';

const promptsDir = join(process.cwd(), 'config', 'prompts');
const basePrompt = readFileSync(join(promptsDir, 'system.md'), 'utf8');
const toolGuidance = readFileSync(join(promptsDir, 'tool-guidance.md'), 'utf8');

export function renderRetrieved(chunks: RetrievedChunk[]): string {
  if (chunks.length === 0) return '';
  return chunks
    .map((c) => `### ${c.title} (${c.source})\n${c.body}`)
    .join('\n\n');
}

export function renderHistory(state: ConversationState): string {
  return state.turns
    .map((t) => (t.role === 'tool' ? `[${t.toolName}] ${t.content}` : `${t.role}: ${t.content}`))
    .join('\n');
}

/**
 * Build the messages for a turn.
 *
 * The workspace custom instructions are part of the system message. Admins
 * configure them to set tone and local policy, so they have to carry the same
 * weight as the rest of the system prompt or they get ignored. See docs/adr/0005.
 */
export function assemble(
  state: ConversationState,
  userMessage: string,
  retrieved: RetrievedChunk[],
) {
  const ws = forWorkspace(state.workspaceId);

  const system = [
    basePrompt,
    toolGuidance,
    ws.customInstructions ? `## Workspace policy\n\n${ws.customInstructions}` : '',
  ]
    .filter(Boolean)
    .join('\n\n');

  const user = [
    renderHistory(state),
    retrieved.length ? `## Supporting content\n\n${renderRetrieved(retrieved)}` : '',
    `user: ${userMessage}`,
  ]
    .filter(Boolean)
    .join('\n\n');

  return { system, user };
}
