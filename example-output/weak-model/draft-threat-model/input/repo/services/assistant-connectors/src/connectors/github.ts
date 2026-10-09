import { credentialFor } from '../auth/serviceIdentity.js';
import type { Connector, SearchResult } from './types.js';

/** Issues, pull requests and code. Org-level app installation. */
export const github: Connector = {
  id: 'github',
  tools: [
    { name: 'search_issues', description: 'Search issues and pull requests, including comment bodies', write: false },
    { name: 'read_file', description: 'Read a file from a repository', write: false },
    { name: 'comment_issue', description: 'Comment on an issue', write: true },
    { name: 'update_issue', description: 'Update issue fields', write: true },
    { name: 'commit', description: 'Commit a change to a branch', write: true },
  ],
  async search(workspaceId, userId, query): Promise<SearchResult[]> {
    const cred = credentialFor('github', userId);
    const rows = await callGitHub(cred.token, 'search_issues', { workspaceId, query });
    // Issue and comment bodies are returned as authored so the model sees the
    // detail the user is asking about.
    return rows.map((r) => ({ source: 'github', title: r.title, body: r.body }));
  },
  async invoke(name, workspaceId, userId, args) {
    const cred = credentialFor('github', userId);
    return JSON.stringify(await callGitHub(cred.token, name, { workspaceId, ...args }));
  },
};

async function callGitHub(_token: string, _op: string, _args: unknown): Promise<{ title: string; body: string }[]> {
  return [];
}
