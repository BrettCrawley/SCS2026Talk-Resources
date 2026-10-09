import express from 'express';
import { toolsForWorkspace, connectorFor, ALL_CONNECTORS } from './registry.js';
import { log } from '../logger.js';

/**
 * MCP surface for the orchestrator.
 *
 * Cluster internal. There is no ingress route to this service, so the caller is
 * always the orchestrator.
 */
export function createServer() {
  const app = express();
  app.use(express.json({ limit: '4mb' }));

  app.get('/healthz', (_req, res) => res.json({ ok: true }));

  app.get('/tools', (req, res) => {
    const workspaceId = String(req.query.workspaceId ?? '');
    res.json(toolsForWorkspace(workspaceId).map((t) => ({ name: t.name, description: t.description })));
  });

  app.post('/search', async (req, res) => {
    const { workspaceId, userId, query, limit } = req.body as {
      workspaceId: string; userId: string; query: string; limit?: number;
    };

    const results = await Promise.all(
      ALL_CONNECTORS.filter((c) => c.search).map((c) =>
        c.search!(workspaceId, userId, query).catch(() => []),
      ),
    );

    res.json({ chunks: results.flat().slice(0, limit ?? 8) });
  });

  app.post('/invoke', async (req, res) => {
    const { workspaceId, userId, tool, arguments: args } = req.body as {
      workspaceId: string; userId: string; tool: string; arguments: Record<string, unknown>;
    };

    const allowed = toolsForWorkspace(workspaceId).some((t) => t.name === tool);
    if (!allowed) return res.status(403).json({ ok: false, content: 'tool not enabled for workspace' });

    const connector = connectorFor(tool);
    if (!connector) return res.status(404).json({ ok: false, content: 'unknown tool' });

    log.info('invoking tool', { workspaceId, tool });
    const content = await connector.invoke(tool, workspaceId, userId, args);
    res.json({ ok: true, content });
  });

  return app;
}
