import { credentialFor } from '../auth/serviceIdentity.js';
import type { Connector, SearchResult } from './types.js';

/**
 * Slack. The app was installed with the full scope set during the prototype so
 * we stopped going back to IT for each permission. PLAT-2814-6 narrows it.
 */
export const slack: Connector = {
  id: 'slack',
  tools: [
    { name: 'search_messages', description: 'Search channels and DMs in the workspace', write: false },
    { name: 'post_message', description: 'Post a message to a channel', write: true },
  ],
  async search(workspaceId, userId, query): Promise<SearchResult[]> {
    const cred = credentialFor('slack', userId);
    const rows = await callSlack(cred.token, 'search', { workspaceId, query });
    return rows.map((r) => ({ source: 'slack', title: r.channel, body: r.text }));
  },
  async invoke(name, workspaceId, userId, args) {
    const cred = credentialFor('slack', userId);
    return JSON.stringify(await callSlack(cred.token, name, { workspaceId, ...args }));
  },
};

async function callSlack(_token: string, _op: string, _args: unknown): Promise<{ channel: string; text: string }[]> {
  return [];
}
