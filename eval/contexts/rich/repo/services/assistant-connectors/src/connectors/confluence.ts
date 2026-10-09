import { credentialFor } from '../auth/serviceIdentity.js';
import type { Connector, SearchResult } from './types.js';

/**
 * Confluence. Added 2026-07-14 for the Support pilot, who wanted the assistant
 * reading the runbook space. Read only, so it went in as a config change.
 */
export const confluence: Connector = {
  id: 'confluence',
  tools: [
    { name: 'search_pages', description: 'Search Confluence pages', write: false },
  ],
  async search(workspaceId, userId, query): Promise<SearchResult[]> {
    const cred = credentialFor('confluence', userId);
    const rows = await callConfluence(cred.token, { workspaceId, query });
    return rows.map((r) => ({ source: 'confluence', title: r.title, body: r.body }));
  },
  async invoke(_name, workspaceId, userId, args) {
    const cred = credentialFor('confluence', userId);
    return JSON.stringify(await callConfluence(cred.token, { workspaceId, ...args }));
  },
};

async function callConfluence(_token: string, _args: unknown): Promise<{ title: string; body: string }[]> {
  return [];
}
