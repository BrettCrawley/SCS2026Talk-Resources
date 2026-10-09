import { request } from 'undici';
import { config } from '../config.js';
import type { RetrievedChunk } from '../types.js';

/**
 * Pull supporting content for the turn from the connectors that support search.
 *
 * Confluence and GitHub both return authored prose. We return the body as it is
 * stored, because summarising it here would lose the detail the agent asked for.
 */
export async function gather(workspaceId: string, query: string): Promise<RetrievedChunk[]> {
  const res = await request(`${config.connectorsUrl}/search`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ workspaceId, query, limit: 8 }),
  });

  if (res.statusCode !== 200) return [];
  const body = (await res.body.json()) as { chunks: RetrievedChunk[] };
  return body.chunks;
}
