import { credentialFor } from '../auth/serviceIdentity.js';
import { sanitiseWebContent } from '../sanitise/webContent.js';
import type { Connector, SearchResult } from './types.js';

/** Community MCP server. The only connector reaching content from outside. */
export const websearch: Connector = {
  id: 'websearch',
  tools: [{ name: 'web_search', description: 'Search the public web', write: false }],
  async search(_workspaceId, userId, query): Promise<SearchResult[]> {
    const cred = credentialFor('websearch', userId);
    const rows = await callSearch(cred.token, query);
    return rows.map((r) => ({
      source: 'websearch',
      title: r.title,
      body: sanitiseWebContent(r.body),
    }));
  },
  async invoke(_name, workspaceId, userId, args) {
    return JSON.stringify(await this.search!(workspaceId, userId, String(args.query ?? '')));
  },
};

async function callSearch(_key: string, _q: string): Promise<{ title: string; body: string }[]> {
  return [];
}
