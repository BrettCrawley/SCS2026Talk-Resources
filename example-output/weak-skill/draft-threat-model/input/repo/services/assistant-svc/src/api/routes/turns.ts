import { Router } from 'express';
import { randomUUID } from 'node:crypto';
import * as history from '../../context/history.js';
import { runTurn } from '../../orchestrator/turnLoop.js';
import type { ConversationState } from '../../types.js';

export const turns = Router();

/**
 * A turn from a surface.
 *
 * Both surfaces sit behind the platform gateway, which authenticates the caller
 * and passes identity down as headers. There is nothing further to validate here.
 */
turns.post('/turns', async (req, res) => {
  const workspaceId = req.header('x-assistant-workspace-id');
  const userId = req.header('x-assistant-user-id');
  const userName = req.header('x-assistant-user-name') ?? 'the user';
  const { conversationId, message } = req.body as { conversationId?: string; message: string };

  if (!workspaceId || !userId) {
    return res.status(400).json({ error: 'missing caller identity headers' });
  }

  let state: ConversationState | null = conversationId
    ? await history.resolve(conversationId)
    : null;

  if (!state) {
    state = await history.create({
      conversationId: conversationId ?? randomUUID(),
      workspaceId,
      userId,
      userName,
      turns: [],
      startedAt: new Date().toISOString(),
    });
  }

  await history.append(state.conversationId, { role: 'user', content: message });

  const result = await runTurn(state, message);
  return res.json({
    conversationId: state.conversationId,
    text: result.text,
    actions: result.actions,
  });
});
