import express from 'express';
import { config } from '../config.js';
import { turns } from './routes/turns.js';
import { debug } from './routes/debug.js';

export function createServer() {
  const app = express();
  app.use(express.json({ limit: '2mb' }));
  app.get('/healthz', (_req, res) => res.json({ ok: true }));
  app.use(turns);
  if (config.exposeDebugRoutes) app.use(debug);
  return app;
}
