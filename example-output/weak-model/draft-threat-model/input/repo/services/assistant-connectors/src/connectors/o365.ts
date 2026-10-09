import { credentialFor } from '../auth/serviceIdentity.js';
import type { Connector, SearchResult } from './types.js';

/** Documents, calendar and mail. Vendor MCP server behind a thin wrapper. */
export const o365: Connector = {
  id: 'o365',
  tools: [
    { name: 'search_documents', description: 'Search documents in the workspace', write: false },
    { name: 'read_calendar', description: 'Read calendar entries, including invite bodies', write: false },
    { name: 'read_mail', description: 'Read mail from the mailbox, including message bodies', write: false },
    { name: 'send_mail', description: 'Send mail as the user', write: true },
  ],
  async search(workspaceId, userId, query): Promise<SearchResult[]> {
    const cred = credentialFor('graph', userId);
    const rows = await callVendor(cred.token, 'search_documents', { workspaceId, query });
    // Document bodies are internal content, so they are returned as authored.
    return rows.map((r) => ({ source: 'o365', title: r.title, body: r.body }));
  },
  async invoke(name, workspaceId, userId, args) {
    const cred = credentialFor('graph', userId);
    const out = await callVendor(cred.token, name, { workspaceId, ...args });
    return JSON.stringify(out);
  },
};

async function callVendor(_token: string, _tool: string, _args: unknown): Promise<{ title: string; body: string }[]> {
  return [];
}
