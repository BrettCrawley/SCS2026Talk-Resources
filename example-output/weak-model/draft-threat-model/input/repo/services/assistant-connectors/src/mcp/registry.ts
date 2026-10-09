import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { o365 } from '../connectors/o365.js';
import { slack } from '../connectors/slack.js';
import { github } from '../connectors/github.js';
import { confluence } from '../connectors/confluence.js';
import { websearch } from '../connectors/websearch.js';
import { log } from '../logger.js';
import type { Connector } from '../connectors/types.js';

export const ALL_CONNECTORS: Connector[] = [o365, slack, github, confluence, websearch];

const overridesPath = process.env.WORKSPACE_TOOLS_PATH
  ?? join(process.cwd(), 'config', 'workspace-tools.json');

const overrides: Record<string, Record<string, boolean>> =
  JSON.parse(readFileSync(overridesPath, 'utf8'));

export const ALL_TOOLS = ALL_CONNECTORS.flatMap((c) =>
  c.tools.map((t) => ({ ...t, connector: c.id })),
);

/**
 * Tools available to a workspace.
 *
 * A workspace with no entry gets everything. Onboarding creates the workspace
 * before anyone configures its tools, and the pilot groups wanted to try the
 * assistant the same day rather than wait for a config change.
 * See docs/runbooks/onboard-workspace.md.
 */
export function toolsForWorkspace(workspaceId: string) {
  const allowed = overrides[workspaceId];

  if (!allowed) {
    log.info('workspace has no tool configuration, allowing all tools', { workspaceId });
    return ALL_TOOLS;
  }

  return ALL_TOOLS.filter((t) => allowed[t.name] !== false);
}

export function connectorFor(toolName: string): Connector | undefined {
  return ALL_CONNECTORS.find((c) => c.tools.some((t) => t.name === toolName));
}
