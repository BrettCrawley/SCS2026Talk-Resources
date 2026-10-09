import { Router } from 'express';
import * as history from '../../context/history.js';

export const debug = Router();

/**
 * Support routes for the pilot. The runbook for a bad assistant reply asks the
 * on-call engineer to pull the conversation and see what was in context.
 */
debug.get('/internal/debug/conversations/:id', async (req, res) => {
  const state = await history.resolve(req.params.id);
  if (!state) return res.status(404).json({ error: 'not found' });
  return res.json(state);
});

debug.get('/internal/debug/config', (_req, res) => {
  return res.json({
    node: process.version,
    env: Object.fromEntries(
      Object.entries(process.env).filter(([k]) => !/KEY|SECRET|TOKEN|PASSWORD/i.test(k)),
    ),
  });
});
